import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { db } from "@/lib/db";

vi.mock("@/lib/auth/auth", () => ({ auth: vi.fn() }));
vi.mock("next/cache", () => ({ revalidatePath: vi.fn() }));
vi.mock("@/lib/rate-limit", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/lib/rate-limit")>();
  return { ...actual, rateLimit: vi.fn(actual.rateLimit) };
});

import { auth } from "@/lib/auth/auth";
import { revalidatePath } from "next/cache";
import { rateLimit } from "@/lib/rate-limit";
import { saveGradeAction } from "./actions";
import { saveGrade, SAVE_GRADE_MESSAGES } from "./save-grade";
import { createGiaoVienWorld, type GiaoVienWorld } from "@/test/giao-vien-world";

let world: GiaoVienWorld;

beforeAll(async () => {
  world = await createGiaoVienWorld();
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

beforeEach(async () => {
  await db.grade.deleteMany({
    where: {
      submissionId: { in: [world.submissionA, world.submissionB, world.submissionMismatch] },
    },
  });
  await db.notification.deleteMany({
    where: { userId: { in: [world.parentUser.id, world.otherParentUserId] } },
  });
  await db.activityLog.deleteMany({ where: { studentId: world.studentUser.profileId } });
  await db.subjectWeekScore.deleteMany({ where: { studentId: world.studentUser.profileId } });
  vi.mocked(revalidatePath).mockClear();
});

function signInAs(userId: string | null): void {
  vi.mocked(auth).mockResolvedValue(
    (userId === null ? null : { user: { id: userId }, expires: "" }) as never,
  );
}

const baseInput = (submissionId: string) => ({
  submissionId,
  essayScore: 3.5,
  feedback: "Tốt lắm",
  shouldNotifyParent: false,
});

describe("saveGradeAction authentication", () => {
  it("answers UNAUTHENTICATED without a session", async () => {
    signInAs(null);

    const result = await saveGradeAction(baseInput(world.submissionA));

    expect(result).toMatchObject({ ok: false, error: { code: "UNAUTHENTICATED" } });
  });

  it("answers FORBIDDEN for a student and for a parent", async () => {
    signInAs(world.studentUser.id);
    const asStudent = await saveGradeAction(baseInput(world.submissionA));
    signInAs(world.parentUser.id);
    const asParent = await saveGradeAction(baseInput(world.submissionA));

    expect(asStudent).toMatchObject({ ok: false, error: { code: "FORBIDDEN" } });
    expect(asParent).toMatchObject({ ok: false, error: { code: "FORBIDDEN" } });
    expect(await db.grade.count({ where: { submissionId: world.submissionA } })).toBe(0);
  });
});

describe("saveGradeAction failures", () => {
  it("answers INTERNAL and stores nothing when the rate limiter itself fails", async () => {
    signInAs(world.teacherA.id);
    vi.mocked(rateLimit).mockRejectedValueOnce(new Error("limiter down"));

    const result = await saveGradeAction(baseInput(world.submissionA));

    expect(result).toMatchObject({ ok: false, error: { code: "INTERNAL" } });
    expect(await db.grade.count({ where: { submissionId: world.submissionA } })).toBe(0);
  });

  it("answers RATE_LIMITED when the limiter refuses", async () => {
    signInAs(world.teacherA.id);
    vi.mocked(rateLimit).mockResolvedValueOnce({ isAllowed: false, remaining: 0, retryAfterMs: 1 });

    const result = await saveGradeAction(baseInput(world.submissionA));

    expect(result).toMatchObject({ ok: false, error: { code: "RATE_LIMITED" } });
  });
});

describe("saveGradeAction as the owning teacher", () => {
  it("stores the grade, revalidates both screens and reports success", async () => {
    signInAs(world.teacherA.id);

    const result = await saveGradeAction(baseInput(world.submissionA));

    const grade = await db.grade.findUnique({ where: { submissionId: world.submissionA } });
    expect(result).toMatchObject({
      ok: true,
      data: { essayScore: 3.5, message: SAVE_GRADE_MESSAGES.saved },
    });
    expect(grade).toMatchObject({
      essayScore: 3.5,
      feedback: "Tốt lắm",
      gradedById: world.teacherA.profileId,
    });
    expect(grade?.notifiedAt).toBeNull();
    expect(revalidatePath).toHaveBeenCalledWith("/giao-vien");
    expect(revalidatePath).toHaveBeenCalledWith("/phu-huynh");
  });

  it("does not revalidate when the save fails", async () => {
    signInAs(world.teacherA.id);

    await saveGradeAction({ ...baseInput(world.submissionA), essayScore: 99 });

    expect(revalidatePath).not.toHaveBeenCalled();
  });
});

describe("saveGrade authorization", () => {
  it("gives teacher B the same answer for A's submission as for a missing one", async () => {
    const foreign = await saveGrade(world.teacherB, baseInput(world.submissionA));
    const missing = await saveGrade(world.teacherB, baseInput("no-such-submission"));

    expect(foreign).toEqual(missing);
    expect(foreign).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.grade.count({ where: { submissionId: world.submissionA } })).toBe(0);
  });

  it("does not let teacher A grade teacher B's submission", async () => {
    const result = await saveGrade(world.teacherA, baseInput(world.submissionB));

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.grade.count({ where: { submissionId: world.submissionB } })).toBe(0);
  });

  it("rejects a submission whose student is not enrolled in the assessment's class", async () => {
    const result = await saveGrade(world.teacherA, baseInput(world.submissionMismatch));

    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
    expect(await db.grade.count({ where: { submissionId: world.submissionMismatch } })).toBe(0);
  });
});

describe("saveGrade validation", () => {
  it.each([4.25, 99, Number.NaN, Number.POSITIVE_INFINITY, -1, 3.1])(
    "rejects score %s and stores nothing",
    async (essayScore) => {
      const result = await saveGrade(world.teacherA, {
        ...baseInput(world.submissionA),
        essayScore,
      });

      expect(result).toMatchObject({ ok: false });
      expect(await db.grade.count({ where: { submissionId: world.submissionA } })).toBe(0);
    },
  );

  it("accepts the maximum score exactly", async () => {
    const result = await saveGrade(world.teacherA, {
      ...baseInput(world.submissionA),
      essayScore: 4,
    });

    expect(result).toMatchObject({ ok: true, data: { essayScore: 4 } });
  });
});

describe("saveGrade persistence", () => {
  it("is an upsert: saving twice keeps one Grade with the latest values", async () => {
    await saveGrade(world.teacherA, baseInput(world.submissionA));
    await saveGrade(world.teacherA, {
      ...baseInput(world.submissionA),
      essayScore: 2,
      feedback: "",
    });

    const grades = await db.grade.findMany({ where: { submissionId: world.submissionA } });
    expect(grades).toHaveLength(1);
    expect(grades[0]).toMatchObject({ essayScore: 2, feedback: null });
  });

  it("notifies only the student's own parents and stamps notifiedAt", async () => {
    const result = await saveGrade(world.teacherA, {
      ...baseInput(world.submissionA),
      shouldNotifyParent: true,
    });

    const own = await db.notification.findMany({ where: { userId: world.parentUser.id } });
    const other = await db.notification.count({ where: { userId: world.otherParentUserId } });
    const grade = await db.grade.findUnique({ where: { submissionId: world.submissionA } });
    expect(result).toMatchObject({ ok: true, data: { notifiedParents: 1 } });
    expect(own).toHaveLength(1);
    expect(own[0]).toMatchObject({ kind: "GRADE_PUBLISHED", href: "/phu-huynh" });
    expect(other).toBe(0);
    expect(grade?.notifiedAt).not.toBeNull();
  });

  it("creates no notification when the flag is off", async () => {
    await saveGrade(world.teacherA, baseInput(world.submissionA));

    expect(await db.notification.count({ where: { userId: world.parentUser.id } })).toBe(0);
  });
});

const notifyInput = (essayScore: number) => ({
  ...baseInput(world.submissionA),
  essayScore,
  shouldNotifyParent: true,
});

describe("saveGrade parent notifications", () => {
  it("sends one notification when the same grade is re-saved with the box ticked", async () => {
    await saveGrade(world.teacherA, notifyInput(3.5));
    const firstStamp = (
      await db.grade.findUniqueOrThrow({ where: { submissionId: world.submissionA } })
    ).notifiedAt;

    const second = await saveGrade(world.teacherA, notifyInput(3.5));

    const grade = await db.grade.findUniqueOrThrow({ where: { submissionId: world.submissionA } });
    expect(second).toMatchObject({
      ok: true,
      data: { notifiedParents: 0, message: SAVE_GRADE_MESSAGES.alreadyNotified },
    });
    expect(await db.notification.count({ where: { userId: world.parentUser.id } })).toBe(1);
    expect(grade.notifiedAt).toEqual(firstStamp);
  });

  it("notifies again when the score changes", async () => {
    await saveGrade(world.teacherA, notifyInput(3.5));

    await saveGrade(world.teacherA, notifyInput(4));

    expect(await db.notification.count({ where: { userId: world.parentUser.id } })).toBe(2);
  });

  it("notifies a grade that was first saved without the box ticked", async () => {
    await saveGrade(world.teacherA, baseInput(world.submissionA));

    const result = await saveGrade(world.teacherA, notifyInput(3.5));

    expect(result).toMatchObject({ ok: true, data: { notifiedParents: 1 } });
    expect(await db.notification.count({ where: { userId: world.parentUser.id } })).toBe(1);
  });
});

describe("saveGrade dashboard records", () => {
  const activityRows = () =>
    db.activityLog.findMany({ where: { studentId: world.studentUser.profileId } });
  const weekScores = () =>
    db.subjectWeekScore.findMany({ where: { studentId: world.studentUser.profileId } });

  it("records an activity entry and the subject score for a new grade", async () => {
    await saveGrade(world.teacherA, baseInput(world.submissionA));

    const [activity] = await activityRows();
    const scores = await weekScores();
    expect(activity).toMatchObject({
      kind: "EXAM_COMPLETED",
      tags: [{ label: "Đã chấm chi tiết", tone: "neutral" }],
    });
    expect(activity?.title).toContain("Giáo viên đã chấm bài");
    expect(JSON.stringify(activity?.description)).toContain("8.5 / 10.0 điểm");
    expect(scores).toHaveLength(1);
    expect(scores[0]).toMatchObject({ subject: "MATH", score: 8.5 });
  });

  it("does not duplicate activity rows when the same grade is re-saved", async () => {
    await saveGrade(world.teacherA, baseInput(world.submissionA));
    await saveGrade(world.teacherA, { ...baseInput(world.submissionA), feedback: "Khác" });
    await saveGrade(world.teacherA, notifyInput(3.5));

    expect(await activityRows()).toHaveLength(1);
    expect(await weekScores()).toHaveLength(1);
  });

  it("adds an entry and keeps the latest week score when the score changes", async () => {
    await saveGrade(world.teacherA, baseInput(world.submissionA));
    await saveGrade(world.teacherA, { ...baseInput(world.submissionA), essayScore: 2 });

    const scores = await weekScores();
    expect(await activityRows()).toHaveLength(2);
    expect(scores).toHaveLength(1);
    expect(scores[0]?.score).toBe(7);
  });

  it("records nothing when the grade is rejected", async () => {
    await saveGrade(world.teacherA, { ...baseInput(world.submissionA), essayScore: 99 });
    await saveGrade(world.teacherB, baseInput(world.submissionA));

    expect(await activityRows()).toHaveLength(0);
    expect(await weekScores()).toHaveLength(0);
  });
});
