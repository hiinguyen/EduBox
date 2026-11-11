import { afterAll, beforeAll, describe, expect, it, vi } from "vitest";
import { db } from "@/lib/db";
import { MS_PER_DAY, MS_PER_MINUTE } from "@/lib/format/time";
import { EXAM_DURATION_MINUTES, createExamWorld } from "@/test/exam-world";
import type { ExamWorld } from "@/test/exam-world";
import { START_RATE_LIMIT } from "./constants";
import { getExamPage } from "./exam-session";
import { startAttemptFor } from "./start-attempt";

vi.mock("@/lib/auth/auth", () => ({ auth: vi.fn() }));

let world: ExamWorld;

beforeAll(async () => {
  world = await createExamWorld();
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

describe("starting an exam", () => {
  it("does not create an attempt when the page is only viewed", async () => {
    const student = await world.createStudent();

    const withId = await getExamPage(student, world.exam.id);
    const withoutId = await getExamPage(student);

    expect(withId.kind).toBe("intro");
    expect(withoutId.kind).toBe("intro");
    expect(await db.examAttempt.count({ where: { studentId: student.profileId } })).toBe(0);
  });

  it("creates the attempt only through the start action, with a server deadline", async () => {
    const student = await world.createStudent();
    const now = new Date();

    const result = await startAttemptFor(student, { assessmentId: world.exam.id }, now);

    const attempt = await db.examAttempt.findFirstOrThrow({
      where: { studentId: student.profileId },
    });
    expect(result).toEqual({ ok: true, data: { attemptId: attempt.id } });
    expect(attempt.endsAt.getTime()).toBe(now.getTime() + EXAM_DURATION_MINUTES * MS_PER_MINUTE);
    expect((await getExamPage(student, world.exam.id)).kind).toBe("session");
  });

  it("caps the deadline at the due date when it comes before the full duration", async () => {
    const now = new Date();
    const dueAt = new Date(now.getTime() + 10 * MS_PER_MINUTE);
    const exam = await world.createExam({ name: "due-soon", dueAt });
    const student = await world.createStudent();

    await world.startExam(student, exam.id, now);

    const attempt = await db.examAttempt.findFirstOrThrow({
      where: { studentId: student.profileId },
    });
    expect(attempt.endsAt.getTime()).toBe(dueAt.getTime());
  });

  it("rejects starting after the due date", async () => {
    const now = new Date();
    const exam = await world.createExam({ name: "overdue", dueAt: new Date(now.getTime() - 1) });
    const student = await world.createStudent();

    const result = await startAttemptFor(student, { assessmentId: exam.id }, now);

    expect(result).toMatchObject({ ok: false, error: { code: "CONFLICT" } });
    expect(await db.examAttempt.count({ where: { studentId: student.profileId } })).toBe(0);
    const page = await getExamPage(student, exam.id, now);
    expect(page).toMatchObject({ kind: "intro", intro: { isOverdue: true } });
  });

  it("rejects an exam that is not published", async () => {
    const closed = await world.createExam({ name: "closed", status: "CLOSED" });
    const student = await world.createStudent();

    const result = await startAttemptFor(student, { assessmentId: closed.id });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.examAttempt.count({ where: { studentId: student.profileId } })).toBe(0);
  });

  it("rejects a student who is not enrolled in the class", async () => {
    const outsider = await world.createStudent(world.otherClassId);

    const result = await startAttemptFor(outsider, { assessmentId: world.exam.id });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await getExamPage(outsider, world.exam.id)).toEqual({ kind: "none" });
    expect(await db.examAttempt.count({ where: { studentId: outsider.profileId } })).toBe(0);
  });

  it("rejects malformed input and client supplied deadlines", async () => {
    const student = await world.createStudent();
    const endsAt = new Date(Date.now() + MS_PER_DAY).toISOString();

    const result = await startAttemptFor(student, { assessmentId: world.exam.id, endsAt });

    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
  });

  it("creates exactly one attempt when started concurrently and keeps the deadline", async () => {
    const student = await world.createStudent();

    const results = await Promise.all(
      Array.from({ length: 6 }, () => startAttemptFor(student, { assessmentId: world.exam.id })),
    );

    const ids = results.map((result) => (result.ok ? result.data.attemptId : null));
    expect(new Set(ids).size).toBe(1);
    expect(ids[0]).not.toBeNull();
    expect(await db.examAttempt.count({ where: { studentId: student.profileId } })).toBe(1);
  });

  it("resumes the same attempt on a second start", async () => {
    const student = await world.createStudent();
    const first = await world.startExam(student, world.exam.id);
    const later = new Date(Date.now() + 5 * MS_PER_MINUTE);

    const second = await world.startExam(student, world.exam.id, later);

    expect(second).toBe(first);
  });

  it("rate limits starts per user", async () => {
    const student = await world.createStudent();

    const results = [];
    for (let call = 0; call <= START_RATE_LIMIT.limit; call += 1) {
      results.push(await startAttemptFor(student, { assessmentId: world.exam.id }));
    }

    expect(results.at(-1)).toMatchObject({ ok: false, error: { code: "RATE_LIMITED" } });
  });
});

describe("startAttempt server action", () => {
  async function actionsAs(userId: string | null) {
    const { auth } = await import("@/lib/auth/auth");
    vi.mocked(auth).mockResolvedValue((userId ? { user: { id: userId } } : null) as never);
    return import("./actions");
  }

  it("refuses anonymous callers, parents and teachers", async () => {
    const anonymous = await actionsAs(null);
    expect(await anonymous.startAttempt({})).toMatchObject({
      ok: false,
      error: { code: "UNAUTHENTICATED" },
    });
    for (const userId of [world.parentUserId, world.teacherUserId]) {
      const actions = await actionsAs(userId);
      expect(await actions.startAttempt({})).toMatchObject({
        ok: false,
        error: { code: "FORBIDDEN" },
      });
    }
  });

  it("lets a student start and returns the attempt id", async () => {
    const student = await world.createStudent();
    const actions = await actionsAs(student.id);

    const result = await actions.startAttempt({ assessmentId: world.exam.id });

    expect(result.ok).toBe(true);
    expect(await db.examAttempt.count({ where: { studentId: student.profileId } })).toBe(1);
  });
});
