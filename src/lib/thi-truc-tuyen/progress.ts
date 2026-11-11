import { MAX_PERCENT, clampPercent } from "../format/percent";

export type QuestionStatus = "flagged" | "answered" | "unanswered";

export interface ExamProgress {
  readonly total: number;
  readonly answered: number;
  readonly unanswered: number;
  readonly flagged: number;
  readonly percent: number;
}

export function getQuestionStatus(
  questionId: string,
  answers: Readonly<Record<string, string>>,
  flaggedIds: readonly string[],
): QuestionStatus {
  if (flaggedIds.includes(questionId)) return "flagged";
  return questionId in answers ? "answered" : "unanswered";
}

export function getProgress(
  questionIds: readonly string[],
  answers: Readonly<Record<string, string>>,
  flaggedIds: readonly string[],
): ExamProgress {
  const total = questionIds.length;
  const answered = questionIds.filter((id) => id in answers).length;
  const flagged = questionIds.filter((id) => flaggedIds.includes(id)).length;
  const percent = total === 0 ? 0 : clampPercent(Math.round((answered / total) * MAX_PERCENT));
  return { total, answered, unanswered: total - answered, flagged, percent };
}
