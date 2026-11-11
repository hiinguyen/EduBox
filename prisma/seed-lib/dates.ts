import { addVnDays, getVnCalendarDay, startOfVnWeek } from "../../src/lib/format/date";

const DAYS_PER_WEEK = 7;

/** @db.Date columns hold a calendar day, stored as UTC midnight of the VN day (as the app does). */
function toDateColumn(date: Date): Date {
  return new Date(`${getVnCalendarDay(date)}T00:00:00.000Z`);
}

/** The VN calendar day `daysFromToday` away, for @db.Date columns such as StudyDay.day. */
export function vnDay(daysFromToday: number, now: Date = new Date()): Date {
  return toDateColumn(addVnDays(now, daysFromToday));
}

/** Monday starts of the last `count` VN weeks, oldest first, the last one being the current week. */
export function vnWeekStarts(count: number, now: Date = new Date()): readonly Date[] {
  const currentWeek = startOfVnWeek(now);
  return Array.from({ length: count }, (_, index) =>
    toDateColumn(addVnDays(currentWeek, -(count - 1 - index) * DAYS_PER_WEEK)),
  );
}
