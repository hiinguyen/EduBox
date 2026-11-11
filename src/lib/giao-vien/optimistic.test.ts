import { describe, expect, it } from "vitest";
import { applyRecordedGrade, type GradingView } from "./optimistic";
import type { SubmissionDetail, SubmissionRow } from "./types";

function makeRow(id: string, essayScore: number | null): SubmissionRow {
  return {
    id,
    code: id,
    studentName: "Lê Hoàng Nam",
    studentNumber: "1",
    submittedAtLabel: "14:22 Hôm nay",
    multipleChoiceScore: 6,
    essayScore,
  };
}

function makeView(): GradingView {
  const selected: SubmissionDetail = {
    ...makeRow("s1", null),
    submittedTimeLabel: "14:22:18",
    feedback: "",
    isParentNotified: false,
    aiSuggestion: null,
  };
  return {
    rows: [makeRow("s1", null), makeRow("s2", 3), makeRow("s3", null)],
    selected,
    pendingCount: 18,
  };
}

describe("applyRecordedGrade", () => {
  it("sets the score on the row and the detail and lowers the pending count", () => {
    const result = applyRecordedGrade(makeView(), { submissionId: "s1", essayScore: 3.5 });

    expect(result.rows[0]?.essayScore).toBe(3.5);
    expect(result.selected?.essayScore).toBe(3.5);
    expect(result.pendingCount).toBe(17);
  });

  it("keeps the pending count when re-grading an already graded submission", () => {
    const result = applyRecordedGrade(makeView(), { submissionId: "s2", essayScore: 4 });

    expect(result.rows[1]?.essayScore).toBe(4);
    expect(result.pendingCount).toBe(18);
  });

  it("does not mutate the source view", () => {
    const view = makeView();

    applyRecordedGrade(view, { submissionId: "s1", essayScore: 3.5 });

    expect(view.rows[0]?.essayScore).toBeNull();
    expect(view.pendingCount).toBe(18);
  });

  it("leaves everything untouched for an unknown submission", () => {
    const view = makeView();

    expect(applyRecordedGrade(view, { submissionId: "zzz", essayScore: 1 })).toEqual(view);
  });
});
