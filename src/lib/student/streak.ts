import { MS_PER_MINUTE } from "@/lib/format/time";
import { addDaysToVnDay } from "@/lib/format/date";

/** A day counts toward the streak after at least this much study time. */
export const MIN_STREAK_SECONDS = (15 * MS_PER_MINUTE) / 1_000;

export interface StudyDayInput {
  readonly day: string;
  readonly studiedSeconds: number;
}

/**
 * The one streak rule: consecutive VN calendar days (YYYY-MM-DD) with at least
 * MIN_STREAK_SECONDS of study, ending today, or ending yesterday when today has no
 * qualifying study yet (so the streak does not read zero all morning).
 */
export function computeStreak(days: readonly StudyDayInput[], today: string): number {
  const qualifying = new Set(
    days.filter((entry) => entry.studiedSeconds >= MIN_STREAK_SECONDS).map((entry) => entry.day),
  );
  let cursor = qualifying.has(today) ? today : addDaysToVnDay(today, -1);
  let streak = 0;

  while (qualifying.has(cursor)) {
    streak += 1;
    cursor = addDaysToVnDay(cursor, -1);
  }
  return streak;
}
