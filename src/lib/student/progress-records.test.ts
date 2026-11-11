import { describe, expect, it, vi } from "vitest";
import type { Prisma } from "@/generated/prisma/client";
import { recordActivity, recordStudyTime, recordSubjectScore } from "./progress-records";

function fakeTx() {
  const studyUpsert = vi.fn();
  const scoreUpsert = vi.fn();
  const activityCreate = vi.fn();
  const tx = {
    studyDay: { upsert: studyUpsert },
    subjectWeekScore: { upsert: scoreUpsert },
    activityLog: { create: activityCreate },
  } as unknown as Prisma.TransactionClient;
  return { tx, studyUpsert, scoreUpsert, activityCreate };
}

const STUDENT = "student-1";
// 2026-03-01 18:00 UTC is already Monday 02 March 01:00 in Vietnam.
const SUNDAY_EVENING_UTC = new Date("2026-03-01T18:00:00.000Z");

describe("recordStudyTime", () => {
  it("upserts the VN calendar day and increments the seconds", async () => {
    const { tx, studyUpsert } = fakeTx();

    await recordStudyTime(tx, { studentId: STUDENT, at: SUNDAY_EVENING_UTC, seconds: 90 });

    expect(studyUpsert).toHaveBeenCalledWith({
      where: { studentId_day: { studentId: STUDENT, day: new Date("2026-03-02T00:00:00.000Z") } },
      create: { studentId: STUDENT, day: new Date("2026-03-02T00:00:00.000Z"), studiedSeconds: 90 },
      update: { studiedSeconds: { increment: 90 } },
    });
  });

  it("ignores zero, negative and non-finite durations", async () => {
    const { tx, studyUpsert } = fakeTx();

    for (const seconds of [0, -5, Number.NaN]) {
      await recordStudyTime(tx, { studentId: STUDENT, at: SUNDAY_EVENING_UTC, seconds });
    }

    expect(studyUpsert).not.toHaveBeenCalled();
  });
});

describe("recordSubjectScore", () => {
  it("writes the Monday of the VN week with a one decimal score", async () => {
    const { tx, scoreUpsert } = fakeTx();

    await recordSubjectScore(tx, {
      studentId: STUDENT,
      subject: "MATH",
      at: SUNDAY_EVENING_UTC,
      scoreOutOf10: 8.46,
    });

    const weekStart = new Date("2026-03-02T00:00:00.000Z");
    expect(scoreUpsert).toHaveBeenCalledWith({
      where: { studentId_subject_weekStart: { studentId: STUDENT, subject: "MATH", weekStart } },
      create: { studentId: STUDENT, subject: "MATH", weekStart, score: 8.5 },
      update: { score: 8.5 },
    });
  });

  it("clamps scores to the 0..10 range", async () => {
    const { tx, scoreUpsert } = fakeTx();

    await recordSubjectScore(tx, {
      studentId: STUDENT,
      subject: "MATH",
      at: new Date(),
      scoreOutOf10: 12,
    });
    await recordSubjectScore(tx, {
      studentId: STUDENT,
      subject: "MATH",
      at: new Date(),
      scoreOutOf10: -3,
    });

    expect(scoreUpsert.mock.calls.map(([arg]) => arg.update.score)).toEqual([10, 0]);
  });
});

describe("recordActivity", () => {
  it("creates one activity row with the given fields", async () => {
    const { tx, activityCreate } = fakeTx();
    const input = {
      studentId: STUDENT,
      kind: "EXAM_COMPLETED" as const,
      title: "Hoàn thành bài thi",
      description: [{ text: "Đạt ", isEmphasis: false }],
      tags: [{ label: "Đã chấm", tone: "neutral" as const }],
      occurredAt: SUNDAY_EVENING_UTC,
    };

    await recordActivity(tx, input);

    expect(activityCreate).toHaveBeenCalledWith({ data: input });
  });
});
