import { afterAll, beforeAll, describe, expect, it, vi } from "vitest";
import { db } from "@/lib/db";
import { MS_PER_MINUTE } from "@/lib/format/time";
import { QUESTION_COUNT, answerItem, createExamWorld } from "@/test/exam-world";
import type { ExamWorld } from "@/test/exam-world";
import { MAX_QUESTIONS_PER_EXAM, SAVE_RATE_LIMIT, SUBMIT_GRACE_MS } from "./constants";
import { saveAnswersFor } from "./save-answers";

let world: ExamWorld;
const BATCH_TIME_BUDGET_MS = 3_000;

beforeAll(async () => {
  world = await createExamWorld();
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

async function begin() {
  const student = await world.createStudent();
  const attemptId = await world.startExam(student, world.exam.id);
  return { student, attemptId };
}

describe("saveAnswersFor", () => {
  it("stores a batch and overwrites an earlier answer", async () => {
    const { student, attemptId } = await begin();
    const { exam } = world;

    await saveAnswersFor(student, {
      attemptId,
      answers: [answerItem(exam, 0, 0), answerItem(exam, 1, 2)],
    });
    const result = await saveAnswersFor(student, { attemptId, answers: [answerItem(exam, 0, 3)] });

    const rows = await db.attemptAnswer.findMany({ where: { attemptId } });
    expect(result.ok).toBe(true);
    expect(rows).toHaveLength(2);
    expect(rows.find((row) => row.questionId === exam.questionIds[0])?.optionId).toBe(
      exam.optionIds[0]?.[3],
    );
  });

  it("stores flags, cleared options and the server save time", async () => {
    const { student, attemptId } = await begin();
    const now = new Date();

    await saveAnswersFor(
      student,
      { attemptId, answers: [answerItem(world.exam, 1, null, true)] },
      now,
    );

    const row = await db.attemptAnswer.findFirstOrThrow({ where: { attemptId } });
    expect(row).toMatchObject({ optionId: null, isFlagged: true });
    expect(row.answeredAt.getTime()).toBe(now.getTime());
  });

  it("writes a full batch of 200 answers in one quick call", async () => {
    const big = await world.createExam({ name: "big", questionCount: MAX_QUESTIONS_PER_EXAM });
    const student = await world.createStudent();
    const attemptId = await world.startExam(student, big.id);
    const answers = big.questionIds.map((_, index) => answerItem(big, index, index % 4));

    const startedAt = performance.now();
    const result = await saveAnswersFor(student, { attemptId, answers });
    const elapsed = performance.now() - startedAt;

    expect(result.ok).toBe(true);
    expect(await db.attemptAnswer.count({ where: { attemptId } })).toBe(MAX_QUESTIONS_PER_EXAM);
    expect(elapsed).toBeLessThan(BATCH_TIME_BUDGET_MS);
  });

  it("rejects a question that is not part of the exam", async () => {
    const { student, attemptId } = await begin();

    const result = await saveAnswersFor(student, {
      attemptId,
      answers: [{ questionId: "unknown-question", optionId: null, isFlagged: false }],
    });

    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
  });

  it("rejects an option that belongs to another question and writes nothing", async () => {
    const { student, attemptId } = await begin();
    const { exam } = world;

    const result = await saveAnswersFor(student, {
      attemptId,
      answers: [
        { questionId: exam.questionIds[0], optionId: exam.optionIds[1]?.[0], isFlagged: false },
      ],
    });

    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
    expect(await db.attemptAnswer.count({ where: { attemptId } })).toBe(0);
  });

  it("rejects a whole batch when one item is invalid", async () => {
    const { student, attemptId } = await begin();

    const result = await saveAnswersFor(student, {
      attemptId,
      answers: [
        answerItem(world.exam, 0, 0),
        { questionId: "nope", optionId: null, isFlagged: true },
      ],
    });

    expect(result.ok).toBe(false);
    expect(await db.attemptAnswer.count({ where: { attemptId } })).toBe(0);
  });

  it("refuses a client-supplied deadline instead of accepting it", async () => {
    const { student, attemptId } = await begin();
    const before = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });
    const tampered = new Date(before.endsAt.getTime() + 60 * MS_PER_MINUTE).toISOString();

    const result = await saveAnswersFor(student, { attemptId, endsAt: tampered, answers: [] });

    const after = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });
    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
    expect(after.endsAt).toEqual(before.endsAt);
  });

  it("rejects answers once the deadline has passed", async () => {
    const { student, attemptId } = await begin();
    const { endsAt } = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });

    const result = await saveAnswersFor(
      student,
      { attemptId, answers: [answerItem(world.exam, 0, 0)] },
      endsAt,
    );

    expect(result).toMatchObject({ ok: false, error: { code: "CONFLICT" } });
    expect(await db.attemptAnswer.count({ where: { attemptId } })).toBe(0);
  });

  it("accepts answers one millisecond before the deadline", async () => {
    const { student, attemptId } = await begin();
    const { endsAt } = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });

    const result = await saveAnswersFor(
      student,
      { attemptId, answers: [answerItem(world.exam, 0, 0)] },
      new Date(endsAt.getTime() - 1),
    );

    expect(result.ok).toBe(true);
  });

  it("finalizes an attempt that is long overdue instead of leaving it in progress", async () => {
    const { student, attemptId } = await begin();
    const { endsAt } = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });

    await saveAnswersFor(
      student,
      { attemptId, answers: [] },
      new Date(endsAt.getTime() + SUBMIT_GRACE_MS + 1),
    );

    const attempt = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });
    expect(attempt.status).toBe("EXPIRED");
    expect(await db.submission.count({ where: { attemptId } })).toBe(1);
  });

  it("rejects an out of range current question", async () => {
    const { student, attemptId } = await begin();

    const result = await saveAnswersFor(student, {
      attemptId,
      currentIndex: QUESTION_COUNT,
      answers: [],
    });

    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
  });

  it("rejects saving for another student's attempt and writes nothing", async () => {
    const { attemptId } = await begin();
    const intruder = await world.createStudent();

    const result = await saveAnswersFor(intruder, {
      attemptId,
      answers: [answerItem(world.exam, 0, 0)],
    });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.attemptAnswer.count({ where: { attemptId } })).toBe(0);
  });

  it("rejects saving after the attempt was submitted", async () => {
    const { student, attemptId } = await begin();
    const { submitAttemptFor } = await import("./submit-attempt");
    await submitAttemptFor(student, { attemptId });

    const result = await saveAnswersFor(student, {
      attemptId,
      answers: [answerItem(world.exam, 0, 0)],
    });

    expect(result).toMatchObject({ ok: false, error: { code: "CONFLICT" } });
  });

  it("rejects saving after the assessment was closed", async () => {
    const exam = await world.createExam({ name: "close-on-save" });
    const student = await world.createStudent();
    const attemptId = await world.startExam(student, exam.id);
    await db.assessment.update({ where: { id: exam.id }, data: { status: "CLOSED" } });

    const result = await saveAnswersFor(student, { attemptId, answers: [answerItem(exam, 0, 0)] });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.attemptAnswer.count({ where: { attemptId } })).toBe(0);
  });

  it("rejects saving after the student was unenrolled", async () => {
    const { student, attemptId } = await begin();
    await db.enrollment.deleteMany({ where: { studentId: student.profileId } });

    const result = await saveAnswersFor(student, {
      attemptId,
      answers: [answerItem(world.exam, 0, 0)],
    });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.attemptAnswer.count({ where: { attemptId } })).toBe(0);
  });

  it("rate limits saves per user", async () => {
    const { student, attemptId } = await begin();

    const results = [];
    for (let call = 0; call <= SAVE_RATE_LIMIT.limit; call += 1) {
      results.push(await saveAnswersFor(student, { attemptId, answers: [] }));
    }

    expect(results.slice(0, -1).every((result) => result.ok)).toBe(true);
    expect(results.at(-1)).toMatchObject({ ok: false, error: { code: "RATE_LIMITED" } });
  });
});

describe("saveAnswers server action", () => {
  it("returns INTERNAL instead of throwing when the limiter fails", async () => {
    vi.resetModules();
    vi.doMock("@/lib/rate-limit", () => ({
      rateLimit: () => Promise.reject(new Error("limiter down")),
    }));
    vi.doMock("@/lib/auth/session", () => ({
      requireRoleForAction: () =>
        Promise.resolve({ ok: true, user: { id: "u", profileId: "p", role: "STUDENT" } }),
    }));
    const { saveAnswers } = await import("./actions");

    const result = await saveAnswers({ attemptId: "x", answers: [] });

    expect(result).toMatchObject({ ok: false, error: { code: "INTERNAL" } });
    vi.doUnmock("@/lib/rate-limit");
    vi.doUnmock("@/lib/auth/session");
    vi.resetModules();
  });
});
