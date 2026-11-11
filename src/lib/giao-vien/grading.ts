import type { SubmissionRow } from "./types";

const MIN_DECIMALS = 1;
const MAX_DECIMALS = 2;

/** One decimal for whole and half points, two when the quarter step needs it (3.25). */
export function formatScore(score: number): string {
  const rounded = Number(score.toFixed(MAX_DECIMALS));
  return rounded.toFixed(Number.isInteger(rounded * 10) ? MIN_DECIMALS : MAX_DECIMALS);
}

export function formatScoreOutOf(score: number, max: number): string {
  return `${formatScore(score)} / ${formatScore(max)}`;
}

export function needsReview(submission: Pick<SubmissionRow, "essayScore">): boolean {
  return submission.essayScore === null;
}

/** Saved score first, then the AI hint so the teacher can accept or change it, else empty. */
export function getInitialEssayScore(
  essayScore: number | null,
  suggestedScore: number | undefined,
): string {
  const score = essayScore ?? suggestedScore;
  return score === undefined ? "" : String(score);
}

export interface PriorGrade {
  readonly essayScore: number;
  readonly notifiedAt: Date | null;
}

export interface GradeEffects {
  /** A new grade or a different score: the student's dashboard records must be written. */
  readonly hasScoreChanged: boolean;
  /** Parents are told once per score; a re-save of the same score never notifies again. */
  readonly shouldNotifyParents: boolean;
}

export function decideGradeEffects(
  prior: PriorGrade | null,
  next: { readonly essayScore: number; readonly shouldNotifyParent: boolean },
): GradeEffects {
  const hasScoreChanged = prior === null || prior.essayScore !== next.essayScore;
  const wasNotified = prior !== null && prior.notifiedAt !== null;
  return {
    hasScoreChanged,
    shouldNotifyParents: next.shouldNotifyParent && (hasScoreChanged || !wasNotified),
  };
}

const SCORE_SCALE = 10;

/** Total points normalized to a 0..10 scale; null when the assessment has no positive maximum. */
export function toScoreOutOf10(totalScore: number, maxScore: number): number | null {
  if (!(maxScore > 0)) return null;
  return (totalScore / maxScore) * SCORE_SCALE;
}
