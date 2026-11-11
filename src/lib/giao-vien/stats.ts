import { roundTo } from "@/lib/format/number";
import type { CompletionRate } from "./types";

const PERCENT_SCALE = 100;
const PERCENT_DECIMALS = 1;

/**
 * Submitted work over the work that was assigned (one per enrolled student and assessment).
 * Null when nothing was assigned, so the UI never shows a made-up 0% or 100%.
 */
export function computeCompletionRate(submitted: number, expected: number): CompletionRate | null {
  if (expected === 0) return null;

  const percent = roundTo((submitted / expected) * PERCENT_SCALE, PERCENT_DECIMALS);
  return { percent: Math.min(PERCENT_SCALE, percent), submitted, expected };
}

/** Average of (multiple choice + essay) over graded submissions; null when none are graded. */
export function combineAverages(
  multipleChoiceAverage: number | null,
  essayAverage: number | null,
): number | null {
  if (multipleChoiceAverage === null || essayAverage === null) return null;
  return multipleChoiceAverage + essayAverage;
}
