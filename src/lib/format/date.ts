import { MS_PER_DAY, MS_PER_HOUR, MS_PER_MINUTE, MS_PER_SECOND } from "./time";

export const DISPLAY_TIME_ZONE = "Asia/Ho_Chi_Minh";

const DAYS_PER_WEEK = 7;
const MONDAY_INDEX = 1;
const PAD_WIDTH = 2;
const DAY_PATTERN = /^(\d{4})-(\d{2})-(\d{2})$/;

const WEEKDAY_INDEX: Readonly<Record<string, number>> = {
  Sun: 0,
  Mon: 1,
  Tue: 2,
  Wed: 3,
  Thu: 4,
  Fri: 5,
  Sat: 6,
};

// Formatters are costly to build, so they are created once. All pin the time zone.
const partsFormatter = new Intl.DateTimeFormat("en-GB", {
  timeZone: DISPLAY_TIME_ZONE,
  year: "numeric",
  month: "2-digit",
  day: "2-digit",
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  weekday: "short",
  hourCycle: "h23",
});

interface VnParts {
  readonly year: string;
  readonly month: string;
  readonly day: string;
  readonly hour: string;
  readonly minute: string;
  readonly second: string;
  readonly weekday: string;
}

function getVnParts(date: Date): VnParts {
  const parts: Record<string, string> = {};
  for (const part of partsFormatter.formatToParts(date)) {
    parts[part.type] = part.value;
  }
  return {
    year: parts.year ?? "",
    month: parts.month ?? "",
    day: parts.day ?? "",
    hour: parts.hour ?? "",
    minute: parts.minute ?? "",
    second: parts.second ?? "",
    weekday: parts.weekday ?? "",
  };
}

/** Calendar day (YYYY-MM-DD) of `date` in Vietnam time. */
export function getVnCalendarDay(date: Date): string {
  const { year, month, day } = getVnParts(date);
  return `${year}-${month}-${day}`;
}

/**
 * The instant at which the VN calendar day of `date` began. Vietnam has no daylight saving,
 * so the elapsed time since local midnight is the exact distance back to that instant.
 */
export function startOfVnDay(date: Date): Date {
  const { hour, minute, second } = getVnParts(date);
  const elapsedMs =
    Number(hour) * MS_PER_HOUR +
    Number(minute) * MS_PER_MINUTE +
    Number(second) * MS_PER_SECOND +
    date.getUTCMilliseconds();
  return new Date(date.getTime() - elapsedMs);
}

/** Monday 00:00 (VN) of the week containing `date`. */
export function startOfVnWeek(date: Date): Date {
  const weekday = WEEKDAY_INDEX[getVnParts(date).weekday] ?? MONDAY_INDEX;
  const daysSinceMonday = (weekday - MONDAY_INDEX + DAYS_PER_WEEK) % DAYS_PER_WEEK;
  return new Date(startOfVnDay(date).getTime() - daysSinceMonday * MS_PER_DAY);
}

/** Moves `date` by whole days. Valid because VN has a fixed UTC+7 offset all year. */
export function addVnDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * MS_PER_DAY);
}

/** Adds days to a YYYY-MM-DD string and returns the resulting YYYY-MM-DD. */
export function addDaysToVnDay(day: string, days: number): string {
  const match = DAY_PATTERN.exec(day);
  if (!match) {
    throw new RangeError(`Invalid calendar day: ${day}`);
  }
  const base = Date.UTC(Number(match[1]), Number(match[2]) - 1, Number(match[3]));
  const next = new Date(base + days * MS_PER_DAY);
  const pad = (value: number) => String(value).padStart(PAD_WIDTH, "0");
  return `${next.getUTCFullYear()}-${pad(next.getUTCMonth() + 1)}-${pad(next.getUTCDate())}`;
}

/** HH:mm in VN time. */
export function formatVnClock(date: Date): string {
  const { hour, minute } = getVnParts(date);
  return `${hour}:${minute}`;
}

/** "Hôm nay 15:30", "Hôm qua 20:15", otherwise "14/11 07:00". */
export function formatRelativeDayLabel(date: Date, now: Date): string {
  const day = getVnCalendarDay(date);
  const clock = formatVnClock(date);

  if (day === getVnCalendarDay(now)) {
    return `Hôm nay ${clock}`;
  }
  if (day === addDaysToVnDay(getVnCalendarDay(now), -1)) {
    return `Hôm qua ${clock}`;
  }
  const { month, day: dayOfMonth } = getVnParts(date);
  return `${dayOfMonth}/${month} ${clock}`;
}

/** "Vừa xong", "5 phút trước", "7 giờ trước", "2 ngày trước". */
export function formatRelativeAgo(date: Date, now: Date): string {
  const elapsedMs = Math.max(0, now.getTime() - date.getTime());

  if (elapsedMs < MS_PER_MINUTE) {
    return "Vừa xong";
  }
  if (elapsedMs < MS_PER_HOUR) {
    return `${Math.floor(elapsedMs / MS_PER_MINUTE)} phút trước`;
  }
  if (elapsedMs < MS_PER_DAY) {
    return `${Math.floor(elapsedMs / MS_PER_HOUR)} giờ trước`;
  }
  return `${Math.floor(elapsedMs / MS_PER_DAY)} ngày trước`;
}
