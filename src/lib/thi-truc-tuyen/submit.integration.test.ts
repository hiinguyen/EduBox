import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { db } from "@/lib/db";
import { QUESTION_POINTS, answerItem, createExamWorld } from "@/test/exam-world";
import type { ExamWorld } from "@/test/exam-world";
import { SUBMIT_GRACE_MS, SUBMIT_RATE_LIMIT } from "./constants";
import { saveAnswersFor } from "./save-answers";
import { submitAttemptFor } from "./submit-attempt";

vi.mock("@/lib/auth/auth", () => ({ auth: vi.fn() }));

const codeDraws = vi.hoisted(() => ({ queue: [] as number[] }));
vi.mock("node:crypto", async (importOriginal) => {
  const original = await importOriginal<typeof import("node:crypto")>();
  const randomInt = ((...args: Parameters<typeof original.randomInt>) =>
    codeDraws.queue.shift() ?? original.randomInt(...args)) as typeof original.randomInt;
  return { ...original, randomInt };
});

let world: ExamWorld;

beforeAll(async () => {
  world = await createExamWorld();
});

beforeEach(() => {
  codeDraws.queue = [];
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

async function begin(examId = world.exam.id) {
  const student = await world.createStudent();
  const attemptId = await world.startExam(student, examId);
  return { student, attemptId };
}

describe("submitAttemptFor", () => {
  it("grades on the server, creates the submission and a grade for a multiple choice exam", async () => {
    const { student, attemptId } = await begin();
    const { exam } = world;
    await saveAnswersFor(student, {
      attemptId,
      answers: [answerItem(exam, 0, 0), answerItem(exam, 1, 0), answerItem(exam, 2, 1)],
    });

    const result = await submitAttemptFor(student, {
      attemptId,
      answers: [answerItem(exam, 3, 0)],
    });

    const submission = await db.submission.findUniqueOrThrow({
      where: { attemptId },
      include: { grade: true },
    });
    const attempt = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });
    expect(result).toMatchObject({
      ok: true,
      data: { receipt: { status: "SUBMITTED", isPendingReview: false } },
    });
    expect(submission.multipleChoiceScore).toBe(QUESTION_POINTS * 3);
    expect(submission.grade?.essayScore).toBe(0);
    expect(attempt.status).toBe("SUBMITTED");
    expect(attempt.submittedAt).not.toBeNull();
  });

  it("writes an activity row and the weekly subject score when fully auto graded", async () => {
    const { student, attemptId } = await begin();
    await saveAnswersFor(student, { attemptId, answers: [answerItem(world.exam, 0, 0)] });

    await submitAttemptFor(student, { attemptId });

    const activities = await db.activityLog.findMany({ where: { studentId: student.profileId } });
    const scores = await db.subjectWeekScore.findMany({ where: { studentId: student.profileId } });
    expect(activities).toHaveLength(1);
    expect(activities[0]).toMatchObject({ kind: "EXAM_COMPLETED" });
    expect(activities[0]?.title).toContain("Hoàn thành bài thi");
    expect(scores).toHaveLength(1);
    expect(scores[0]).toMatchObject({ subject: "MATH", score: 2.5 });
    expect(await db.studyDay.count({ where: { studentId: student.profileId } })).toBe(0);
  });

  it("leaves an exam with an essay part pending: no grade and no subject score", async () => {
    const { student, attemptId } = await begin(world.essayExam.id);

    const result = await submitAttemptFor(student, { attemptId });

    const submission = await db.submission.findUniqueOrThrow({
      where: { attemptId },
      include: { grade: true },
    });
    expect(result).toMatchObject({ ok: true, data: { receipt: { isPendingReview: true } } });
    expect(submission.grade).toBeNull();
    expect(await db.activityLog.count({ where: { studentId: student.profileId } })).toBe(1);
    expect(await db.subjectWeekScore.count({ where: { studentId: student.profileId } })).toBe(0);
  });

  it("returns only the status, never a score or a correct answer", async () => {
    const { student, attemptId } = await begin();

    const result = await submitAttemptFor(student, {
      attemptId,
      answers: [answerItem(world.exam, 0, 0)],
    });

    expect(result.ok && Object.keys(result.data.receipt).sort()).toEqual([
      "isPendingReview",
      "status",
      "submittedAt",
    ]);
    expect(JSON.stringify(result)).not.toMatch(/score|key|correct/i);
  });

  it("is idempotent: a second call returns the first result and creates nothing", async () => {
    const { student, attemptId } = await begin();
    const { exam } = world;

    const first = await submitAttemptFor(student, { attemptId, answers: [answerItem(exam, 0, 0)] });
    const second = await submitAttemptFor(student, {
      attemptId,
      answers: [answerItem(exam, 0, 3)],
    });

    expect(second).toEqual(first);
    expect(await db.submission.count({ where: { attemptId } })).toBe(1);
    expect(await db.activityLog.count({ where: { studentId: student.profileId } })).toBe(1);
    const stored = await db.attemptAnswer.findMany({ where: { attemptId } });
    expect(stored.map((row) => row.optionId)).toEqual([exam.optionIds[0]?.[0]]);
  });

  it("creates one submission when double submitted concurrently", async () => {
    const { student, attemptId } = await begin();

    const results = await Promise.all([
      submitAttemptFor(student, { attemptId }),
      submitAttemptFor(student, { attemptId }),
    ]);

    expect(results.every((result) => result.ok)).toBe(true);
    expect(await db.submission.count({ where: { attemptId } })).toBe(1);
    expect(await db.activityLog.count({ where: { studentId: student.profileId } })).toBe(1);
  });

  it("takes final answers during the grace period", async () => {
    const { student, attemptId } = await begin();
    const { endsAt } = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });

    const result = await submitAttemptFor(
      student,
      { attemptId, answers: [answerItem(world.exam, 0, 0)] },
      new Date(endsAt.getTime() + SUBMIT_GRACE_MS),
    );

    expect(result).toMatchObject({ ok: true, data: { receipt: { status: "SUBMITTED" } } });
    expect(await db.attemptAnswer.count({ where: { attemptId } })).toBe(1);
  });

  it("finalizes late with the stored answers and drops answers sent after the grace period", async () => {
    const { student, attemptId } = await begin();
    const { exam } = world;
    await saveAnswersFor(student, { attemptId, answers: [answerItem(exam, 0, 0)] });
    const { endsAt } = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });

    const result = await submitAttemptFor(
      student,
      { attemptId, answers: [answerItem(exam, 1, 0)] },
      new Date(endsAt.getTime() + SUBMIT_GRACE_MS + 1),
    );

    const submission = await db.submission.findUniqueOrThrow({ where: { attemptId } });
    expect(result).toMatchObject({ ok: true, data: { receipt: { status: "EXPIRED" } } });
    expect(submission.multipleChoiceScore).toBe(QUESTION_POINTS);
    expect(await db.attemptAnswer.count({ where: { attemptId } })).toBe(1);
  });

  it("rejects submitting another student's attempt", async () => {
    const { attemptId } = await begin();
    const intruder = await world.createStudent();

    const result = await submitAttemptFor(intruder, { attemptId });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.submission.count({ where: { attemptId } })).toBe(0);
    expect((await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } })).status).toBe(
      "IN_PROGRESS",
    );
  });

  it("rejects submitting after the assessment was closed", async () => {
    const exam = await world.createExam({ name: "close-on-submit" });
    const { student, attemptId } = await begin(exam.id);
    await db.assessment.update({ where: { id: exam.id }, data: { status: "CLOSED" } });

    const result = await submitAttemptFor(student, { attemptId });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.submission.count({ where: { attemptId } })).toBe(0);
  });

  it("rejects submitting after the student was unenrolled", async () => {
    const { student, attemptId } = await begin();
    await db.enrollment.deleteMany({ where: { studentId: student.profileId } });

    const result = await submitAttemptFor(student, { attemptId });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.submission.count({ where: { attemptId } })).toBe(0);
  });

  it("rejects unknown questions and options without finalizing", async () => {
    const { student, attemptId } = await begin();

    const result = await submitAttemptFor(student, {
      attemptId,
      answers: [{ questionId: world.exam.questionIds[0], optionId: "nope", isFlagged: false }],
    });

    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
    expect(await db.submission.count({ where: { attemptId } })).toBe(0);
  });

  it("rate limits submissions per user", async () => {
    const { student, attemptId } = await begin();

    const results = [];
    for (let call = 0; call <= SUBMIT_RATE_LIMIT.limit; call += 1) {
      results.push(await submitAttemptFor(student, { attemptId }));
    }

    expect(results.at(-1)).toMatchObject({ ok: false, error: { code: "RATE_LIMITED" } });
  });
});

describe("unique violations while finalizing", () => {
  it("retries a clash on the submission code and then succeeds", async () => {
    const taken = await begin();
    codeDraws.queue = [0];
    await submitAttemptFor(taken.student, { attemptId: taken.attemptId });
    const { student, attemptId } = await begin();
    codeDraws.queue = [0, 0, 1];

    const result = await submitAttemptFor(student, { attemptId });

    expect(result.ok).toBe(true);
    const codes = await db.submission.findMany({
      where: { assessmentId: world.exam.id, attemptId: { in: [taken.attemptId, attemptId] } },
      select: { code: true },
    });
    expect(new Set(codes.map((row) => row.code)).size).toBe(2);
  });

  it("does not retry a conflict on another column and leaves the attempt open", async () => {
    const { student, attemptId } = await begin();
    await db.submission.create({
      data: {
        assessmentId: world.exam.id,
        studentId: student.profileId,
        code: `#OTHER-${attemptId}`,
        multipleChoiceScore: 0,
      },
    });

    const result = await submitAttemptFor(student, { attemptId });

    expect(result).toMatchObject({ ok: false, error: { code: "CONFLICT" } });
    const attempt = await db.examAttempt.findUniqueOrThrow({ where: { id: attemptId } });
    expect(attempt.status).toBe("IN_PROGRESS");
    expect(await db.activityLog.count({ where: { studentId: student.profileId } })).toBe(0);
  });
});

describe("submit server actions", () => {
  async function actionsAs(userId: string | null) {
    const { auth } = await import("@/lib/auth/auth");
    vi.mocked(auth).mockResolvedValue((userId ? { user: { id: userId } } : null) as never);
    return import("./actions");
  }

  it("refuses anonymous callers, parents and teachers", async () => {
    const anonymous = await actionsAs(null);
    expect(await anonymous.saveAnswers({})).toMatchObject({
      ok: false,
      error: { code: "UNAUTHENTICATED" },
    });
    for (const userId of [world.parentUserId, world.teacherUserId]) {
      const actions = await actionsAs(userId);
      expect(await actions.saveAnswers({})).toMatchObject({ error: { code: "FORBIDDEN" } });
      expect(await actions.submitAttempt({})).toMatchObject({ error: { code: "FORBIDDEN" } });
    }
  });

  it("lets the owner save and submit but refuses another student", async () => {
    const { student: owner, attemptId } = await begin();
    const intruder = await world.createStudent();
    const answers = [answerItem(world.exam, 0, 0)];

    const asIntruder = await actionsAs(intruder.id);
    const refusedSave = await asIntruder.saveAnswers({ attemptId, answers });
    const refusedSubmit = await asIntruder.submitAttempt({ attemptId });
    const asOwner = await actionsAs(owner.id);
    const saved = await asOwner.saveAnswers({ attemptId, answers });
    const submitted = await asOwner.submitAttempt({ attemptId });

    expect(refusedSave).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(refusedSubmit).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(saved.ok).toBe(true);
    expect(submitted).toMatchObject({ ok: true, data: { receipt: { status: "SUBMITTED" } } });
  });

  it("returns a typed Vietnamese error without internals for malformed input", async () => {
    const student = await world.createStudent();
    const actions = await actionsAs(student.id);

    const result = await actions.saveAnswers("not an object");

    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
    expect(JSON.stringify(result)).not.toMatch(/at |stack|prisma|zod/i);
  });
});
