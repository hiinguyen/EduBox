import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { db } from "@/lib/db";
import { MS_PER_MINUTE } from "@/lib/format/time";
import {
  EXAM_DURATION_MINUTES,
  QUESTION_COUNT,
  answerItem,
  createExamWorld,
} from "@/test/exam-world";
import type { ExamWorld } from "@/test/exam-world";
import { SUBMIT_GRACE_MS } from "./constants";
import { finalizeExpiredAttempts } from "./expire-attempts";
import { getExamPage } from "./exam-session";
import { saveAnswersFor } from "./save-answers";
import type { ExamSession } from "./types";

let world: ExamWorld;
const ALL_ATTEMPTS_LIMIT = 500;

beforeAll(async () => {
  world = await createExamWorld();
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

async function openSession(student: Parameters<typeof getExamPage>[0], now = new Date()) {
  const page = await getExamPage(student, world.exam.id, now);
  if (page.kind !== "session") throw new Error(`expected a session, got ${page.kind}`);
  return page.session;
}

describe("getExamPage", () => {
  it("shows the intro with exam facts before the student starts", async () => {
    const student = await world.createStudent();

    const page = await getExamPage(student, world.exam.id);

    expect(page).toMatchObject({
      kind: "intro",
      intro: {
        questionCount: QUESTION_COUNT,
        isOverdue: false,
        exam: { id: world.exam.id, durationMinutes: EXAM_DURATION_MINUTES },
      },
    });
  });

  it("offers an exam of the student's class for display when no id is given", async () => {
    const student = await world.createStudent();

    const page = await getExamPage(student);

    expect(page.kind).toBe("intro");
  });

  it("returns nothing for an exam of a class the student is not in", async () => {
    const outsider = await world.createStudent(world.otherClassId);

    expect(await getExamPage(outsider, world.exam.id)).toEqual({ kind: "none" });
    expect(await getExamPage(outsider)).toEqual({ kind: "none" });
    expect(await db.examAttempt.count({ where: { studentId: outsider.profileId } })).toBe(0);
  });

  it("resumes the session with the same server deadline after a reload", async () => {
    const student = await world.createStudent();
    const start = new Date();
    await world.startExam(student, world.exam.id, start);

    const first = await openSession(student, start);
    const second = await openSession(student, new Date(start.getTime() + 5 * MS_PER_MINUTE));

    expect(second.attemptId).toBe(first.attemptId);
    expect(second.endsAt).toBe(start.getTime() + EXAM_DURATION_MINUTES * MS_PER_MINUTE);
    expect(first.phase).toBe("IN_PROGRESS");
    expect(first.serverNow).toBe(start.getTime());
  });

  it("returns the saved answers after a reload", async () => {
    const student = await world.createStudent();
    const attemptId = await world.startExam(student, world.exam.id);
    const { exam } = world;
    await saveAnswersFor(student, {
      attemptId,
      currentIndex: 2,
      answers: [answerItem(exam, 0, 1), answerItem(exam, 1, null, true)],
    });

    const reloaded = await openSession(student);

    expect(reloaded.currentIndex).toBe(2);
    expect(reloaded.answers[exam.questionIds[0] ?? ""]).toMatchObject({
      optionId: exam.optionIds[0]?.[1],
      isFlagged: false,
    });
    expect(reloaded.answers[exam.questionIds[1] ?? ""]).toMatchObject({
      optionId: null,
      isFlagged: true,
    });
  });

  it("never carries correct answers in the serialized payload", async () => {
    const student = await world.createStudent();
    await world.startExam(student, world.exam.id);

    const session: ExamSession = await openSession(student);

    expect(JSON.stringify(session)).not.toMatch(/"(key|answerKey|correct|isCorrect)"/i);
    for (const question of session.questions) {
      expect(Object.keys(question).sort()).toEqual(
        ["id", "levelLabel", "number", "options", "points", "prompt"].sort(),
      );
      for (const option of question.options) {
        expect(Object.keys(option).sort()).toEqual(["id", "label", "text"]);
      }
    }
  });
});

describe("expired attempts", () => {
  async function startLongAgo() {
    const student = await world.createStudent();
    const startedAt = new Date(Date.now() - (EXAM_DURATION_MINUTES + 10) * MS_PER_MINUTE);
    const attemptId = await world.startExam(student, world.exam.id, startedAt);
    return { student, attemptId, startedAt };
  }

  it("finalizes an overdue attempt when the student opens the page", async () => {
    const { student, attemptId } = await startLongAgo();
    await db.attemptAnswer.create({
      data: {
        attemptId,
        questionId: world.exam.questionIds[0] ?? "",
        optionId: world.exam.optionIds[0]?.[0] ?? null,
      },
    });

    const session = await openSession(student);

    const submission = await db.submission.findUniqueOrThrow({ where: { attemptId } });
    expect(session.phase).toBe("EXPIRED");
    expect(session.submission).toMatchObject({ status: "EXPIRED" });
    expect(submission.multipleChoiceScore).toBe(2.5);
    expect(await db.activityLog.count({ where: { studentId: student.profileId } })).toBe(1);
  });

  it("does not finalize during the grace period", async () => {
    const student = await world.createStudent();
    const start = new Date();
    await world.startExam(student, world.exam.id, start);
    const endsAt = start.getTime() + EXAM_DURATION_MINUTES * MS_PER_MINUTE;

    const session = await openSession(student, new Date(endsAt + SUBMIT_GRACE_MS));

    expect(session.phase).toBe("IN_PROGRESS");
  });

  it("is idempotent across repeated page loads", async () => {
    const { student, attemptId } = await startLongAgo();

    await openSession(student);
    await openSession(student);

    expect(await db.submission.count({ where: { attemptId } })).toBe(1);
    expect(await db.activityLog.count({ where: { studentId: student.profileId } })).toBe(1);
  });

  it("finalizeExpiredAttempts finalizes overdue attempts in bulk and respects the limit", async () => {
    const first = await startLongAgo();
    const second = await startLongAgo();
    const fresh = await world.createStudent();
    const freshAttemptId = await world.startExam(fresh, world.exam.id);

    const done = await finalizeExpiredAttempts(new Date(), ALL_ATTEMPTS_LIMIT);
    const again = await finalizeExpiredAttempts(new Date(), ALL_ATTEMPTS_LIMIT);

    expect(done).toBeGreaterThanOrEqual(2);
    expect(again).toBe(0);
    for (const { attemptId } of [first, second]) {
      const attempt = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });
      expect(attempt.status).toBe("EXPIRED");
      expect(await db.submission.count({ where: { attemptId } })).toBe(1);
    }
    const stillOpen = await db.examAttempt.findUniqueOrThrow({ where: { id: freshAttemptId } });
    expect(stillOpen.status).toBe("IN_PROGRESS");
  });

  it("finalizeExpiredAttempts handles at most `limit` attempts per call", async () => {
    await finalizeExpiredAttempts(new Date(), ALL_ATTEMPTS_LIMIT);
    const a = await startLongAgo();
    const b = await startLongAgo();

    const done = await finalizeExpiredAttempts(new Date(), 1);

    const statuses = await db.examAttempt.findMany({
      where: { id: { in: [a.attemptId, b.attemptId] } },
      select: { status: true },
    });
    expect(done).toBe(1);
    expect(statuses.filter((row) => row.status === "EXPIRED")).toHaveLength(1);
  });
});
