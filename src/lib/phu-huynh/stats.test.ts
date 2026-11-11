import { describe, expect, it } from "vitest";
import { averageScore, buildWeeklyStats, type WeeklyStatInput } from "./stats";

const BASE: WeeklyStatInput = {
  studiedSeconds: 14.5 * 3600,
  goalMinutes: 960,
  watchedLessons: 8,
  completedLessons: 6,
  grades: [
    { earned: 9, maxScore: 10 },
    { earned: 8, maxScore: 10 },
  ],
  aiQuestions: 20,
};

function statById(input: WeeklyStatInput, id: string) {
  const stat = buildWeeklyStats(input).find((candidate) => candidate.id === id);
  if (!stat) throw new Error(`missing stat ${id}`);
  return stat;
}

describe("averageScore", () => {
  it("returns null when nothing is graded", () => {
    expect(averageScore([])).toBeNull();
  });

  it("normalises each grade to a 10-point scale before averaging", () => {
    expect(
      averageScore([
        { earned: 9, maxScore: 10 },
        { earned: 40, maxScore: 100 },
      ]),
    ).toBe(6.5);
  });

  it("ignores assessments with a non-positive maximum", () => {
    expect(averageScore([{ earned: 5, maxScore: 0 }])).toBeNull();
  });
});

describe("buildWeeklyStats", () => {
  it("returns the four cards in display order", () => {
    expect(buildWeeklyStats(BASE).map((stat) => stat.id)).toEqual([
      "online-time",
      "lectures",
      "average-score",
      "ai-questions",
    ]);
  });

  it("reports online time against the weekly goal", () => {
    const stat = statById(BASE, "online-time");

    expect(stat.value).toBe("14.5");
    expect(stat.detail).toEqual({ kind: "trend", text: "Đạt 91% mục tiêu tuần" });
    expect(stat.progressPercent).toBe(91);
  });

  it("shows the surplus and caps the bar when the goal is exceeded", () => {
    const stat = statById({ ...BASE, studiedSeconds: 17.5 * 3600 }, "online-time");

    expect(stat.detail).toEqual({ kind: "trend", text: "Đạt 109% mục tiêu tuần (+1.5h)" });
    expect(stat.progressPercent).toBe(100);
  });

  it("computes the share of completed lessons", () => {
    const stat = statById(BASE, "lectures");

    expect(stat.value).toBe("8");
    expect(stat.detail).toMatchObject({ kind: "verified", emphasis: "75%" });
  });

  it("shows a neutral note when no lesson was watched", () => {
    const stat = statById({ ...BASE, watchedLessons: 0, completedLessons: 0 }, "lectures");

    expect(stat.detail.kind).toBe("note");
    expect(stat.progressPercent).toBe(0);
  });

  it("shows a dash when no grade exists", () => {
    const stat = statById({ ...BASE, grades: [] }, "average-score");

    expect(stat.value).toBe("-");
    expect(stat.progressPercent).toBe(0);
  });

  it("counts AI questions against the weekly target", () => {
    const stat = statById(BASE, "ai-questions");

    expect(stat.value).toBe("20");
    expect(stat.progressPercent).toBe(50);
  });
});
