import { needsReview } from "./grading";
import type { SubmissionDetail, SubmissionRow } from "./types";

/** The slice of the board that changes when a grade is recorded. */
export interface GradingView {
  readonly rows: readonly SubmissionRow[];
  readonly selected: SubmissionDetail | null;
  readonly pendingCount: number;
}

export interface RecordedGrade {
  readonly submissionId: string;
  readonly essayScore: number;
}

/**
 * Shows a grade before the server confirms it. React discards this view when the save
 * transition ends, so a failed save rolls back to the server data on its own.
 */
export function applyRecordedGrade(view: GradingView, grade: RecordedGrade): GradingView {
  const target = [...view.rows, ...(view.selected ? [view.selected] : [])].find(
    (item) => item.id === grade.submissionId,
  );
  const wasPending = target !== undefined && needsReview(target);
  return {
    rows: view.rows.map((row) =>
      row.id === grade.submissionId ? { ...row, essayScore: grade.essayScore } : row,
    ),
    selected:
      view.selected?.id === grade.submissionId
        ? { ...view.selected, essayScore: grade.essayScore }
        : view.selected,
    pendingCount: wasPending ? Math.max(0, view.pendingCount - 1) : view.pendingCount,
  };
}
