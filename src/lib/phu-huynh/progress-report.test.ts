import { describe, expect, it } from "vitest";
import { buildProgressReport, type WeekScoreRow } from "./progress-report";

function week(index: number): Date {
  return new Date(Date.UTC(2026, 9, 1 + index * 7));
}

function rows(subject: WeekScoreRow["subject"], scores: readonly number[]): WeekScoreRow[] {
  return scores.map((score, index) => ({ subject, weekStart: week(index), score }));
}

describe("buildProgressReport", () => {
  it("returns null when there are no scores", () => {
    expect(buildProgressReport([], "Minh Anh")).toBeNull();
  });

  it("builds one series per charted subject in legend order", () => {
    const report = buildProgressReport(
      [...rows("ENGLISH", [8, 8.2]), ...rows("MATH", [7, 9])],
      "Minh Anh",
    );

    expect(report?.series.map((series) => series.id)).toEqual(["math", "english"]);
    expect(report?.series[0]?.scores).toEqual([7, 9]);
  });

  it("labels weeks and marks the last one as current", () => {
    const report = buildProgressReport(rows("MATH", [7, 8, 9]), "Minh Anh");

    expect(report?.weekLabels).toEqual(["Tuần 1", "Tuần 2", "Tuần 3 (Hiện tại)"]);
  });

  it("keeps only the six most recent weeks", () => {
    const report = buildProgressReport(rows("MATH", [1, 2, 3, 4, 5, 6, 7, 8]), "Minh Anh");

    expect(report?.series[0]?.scores).toEqual([3, 4, 5, 6, 7, 8]);
  });

  it("highlights the subject with the largest gain and names it in the insight", () => {
    const report = buildProgressReport(
      [...rows("MATH", [7, 7.5]), ...rows("PHYSICS", [6.8, 8.6])],
      "Minh Anh",
    );

    expect(report?.highlightedSeriesId).toBe("physics");
    expect(report?.insight.body).toContain("Vật lý");
    expect(report?.insight.body).toContain("+1.8");
  });

  it("reports stability when no subject improved", () => {
    const report = buildProgressReport(rows("MATH", [8, 7.5]), "Minh Anh");

    expect(report?.insight.body).toContain("ổn định");
  });

  it("omits a subject that misses a week instead of inventing a value", () => {
    const partial = rows("PHYSICS", [7]).map((row) => ({ ...row, weekStart: week(1) }));
    const report = buildProgressReport([...rows("MATH", [7, 8]), ...partial], "Minh Anh");

    expect(report?.series.map((series) => series.id)).toEqual(["math"]);
  });

  it("ignores subjects the chart has no style for", () => {
    const report = buildProgressReport(rows("CHEMISTRY", [7, 8]), "Minh Anh");

    expect(report).toBeNull();
  });
});
