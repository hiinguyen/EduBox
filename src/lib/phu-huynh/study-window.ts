import { addDaysToVnDay, getVnCalendarDay, startOfVnWeek } from "@/lib/format/date";

/** `StudyDay.day` is a `@db.Date`, which Prisma exposes as midnight UTC of the calendar day. */
export function vnDayToDate(day: string): Date {
  return new Date(`${day}T00:00:00.000Z`);
}

export function studyDayKey(day: Date): string {
  return day.toISOString().slice(0, 10);
}

export interface StudyDayRange {
  readonly from: Date;
  readonly to: Date;
}

/** Monday-start Vietnam week up to and including today, as `StudyDay.day` bounds. */
export function currentWeekRange(now: Date): StudyDayRange {
  return {
    from: vnDayToDate(getVnCalendarDay(startOfVnWeek(now))),
    to: vnDayToDate(getVnCalendarDay(now)),
  };
}

/** First `StudyDay.day` of a lookback that reaches `days` Vietnam days before today. */
export function lookbackStart(now: Date, days: number): Date {
  return vnDayToDate(addDaysToVnDay(getVnCalendarDay(now), -days));
}
