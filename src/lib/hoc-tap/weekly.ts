import { addDaysToVnDay, getVnCalendarDay, startOfVnWeek } from "@/lib/format/date";
import { roundTo } from "@/lib/format/number";
import { MAX_PERCENT, clampPercent } from "@/lib/format/percent";
import { MS_PER_DAY } from "@/lib/format/time";

const DAYS_PER_WEEK = 7;
const SECONDS_PER_HOUR = 3_600;
const SECONDS_PER_MINUTE = 60;
const ISO_WEEK_ANCHOR_DAY = 4;
const DAY_KEY_LENGTH = 10;
const ONE_DECIMAL = 1;

export interface StudyDayEntry {
  /** VN calendar day as YYYY-MM-DD. */
  readonly day: string;
  readonly studiedSeconds: number;
}

export interface WeeklyStats {
  readonly hoursLogged: number;
  readonly hoursTarget: number;
  readonly progressPercent: number;
  readonly goalDeltaPercent: number;
  readonly weekSeconds: number;
}

/** A `@db.Date` column is read back as UTC midnight of the stored calendar day. */
export function toCalendarDayKey(column: Date): string {
  return column.toISOString().slice(0, DAY_KEY_LENGTH);
}

export function isoWeekNumber(day: string): number {
  const start = new Date(`${day}T00:00:00Z`);
  const weekday = start.getUTCDay() || DAYS_PER_WEEK;
  const thursday = new Date(start.getTime() + (ISO_WEEK_ANCHOR_DAY - weekday) * MS_PER_DAY);
  const yearStart = Date.UTC(thursday.getUTCFullYear(), 0, 1);
  return Math.ceil(((thursday.getTime() - yearStart) / MS_PER_DAY + 1) / DAYS_PER_WEEK);
}

function sumBetween(entries: readonly StudyDayEntry[], from: string, until: string): number {
  return entries
    .filter((entry) => entry.day >= from && entry.day < until)
    .reduce((total, entry) => total + entry.studiedSeconds, 0);
}

export function computeWeeklyStats(
  entries: readonly StudyDayEntry[],
  now: Date,
  weeklyGoalMinutes: number,
): WeeklyStats {
  const weekStart = getVnCalendarDay(startOfVnWeek(now));
  const previousStart = addDaysToVnDay(weekStart, -DAYS_PER_WEEK);
  const nextStart = addDaysToVnDay(weekStart, DAYS_PER_WEEK);
  const weekSeconds = sumBetween(entries, weekStart, nextStart);
  const previousSeconds = sumBetween(entries, previousStart, weekStart);
  const goalSeconds = weeklyGoalMinutes * SECONDS_PER_MINUTE;
  const rawPercent = goalSeconds > 0 ? (weekSeconds / goalSeconds) * MAX_PERCENT : 0;
  const delta =
    previousSeconds > 0 ? ((weekSeconds - previousSeconds) / previousSeconds) * MAX_PERCENT : 0;

  return {
    weekSeconds,
    hoursLogged: roundTo(weekSeconds / SECONDS_PER_HOUR, ONE_DECIMAL),
    hoursTarget: roundTo(goalSeconds / SECONDS_PER_HOUR, ONE_DECIMAL),
    progressPercent: Math.round(clampPercent(rawPercent)),
    goalDeltaPercent: Math.max(0, Math.round(delta)),
  };
}

export function badgeHint(weeklyMinutesToEarn: number, weekSeconds: number): string {
  const remainingMinutes = weeklyMinutesToEarn - Math.floor(weekSeconds / SECONDS_PER_MINUTE);
  if (remainingMinutes <= 0) return "Bạn đã đủ giờ học tuần này để mở khóa huy hiệu!";
  const hours = roundTo(remainingMinutes / SECONDS_PER_MINUTE, ONE_DECIMAL);
  return `Chỉ còn ${hours} giờ học nữa để mở khóa huy hiệu tuần này!`;
}
