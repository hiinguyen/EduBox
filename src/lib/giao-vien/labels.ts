import { DISPLAY_TIME_ZONE, formatVnClock, getVnCalendarDay } from "@/lib/format/date";

const SECONDS_PER_MINUTE = 60;
const SHORT_NAME_MIN_WORDS = 2;

/** "Cô Nguyễn Thu Hà" -> "cô Hà": honorific plus given name, for running text. */
export function toShortName(fullName: string): string {
  const words = fullName.trim().split(/\s+/);
  const [honorific] = words;
  const givenName = words.at(-1);
  if (words.length < SHORT_NAME_MIN_WORDS || !honorific || !givenName) return fullName.trim();
  return `${honorific.toLocaleLowerCase("vi-VN")} ${givenName}`;
}

/** 2295 -> "38 phút 15 giây". */
export function formatDurationLabel(totalSeconds: number): string {
  const seconds = Math.max(0, Math.floor(totalSeconds));
  const minutes = Math.floor(seconds / SECONDS_PER_MINUTE);
  const rest = String(seconds % SECONDS_PER_MINUTE).padStart(2, "0");
  return `${minutes} phút ${rest} giây`;
}

const TIME_SECONDS_FORMAT = new Intl.DateTimeFormat("en-GB", {
  timeZone: DISPLAY_TIME_ZONE,
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hourCycle: "h23",
});
const DAY_FORMAT = new Intl.DateTimeFormat("en-GB", {
  timeZone: DISPLAY_TIME_ZONE,
  day: "2-digit",
  month: "2-digit",
});

function isSameDay(a: Date, b: Date): boolean {
  return getVnCalendarDay(a) === getVnCalendarDay(b);
}

/** "14:22 Hôm nay" for today, otherwise "14:22 05/11". */
export function formatSubmittedAt(value: Date, now: Date): string {
  const time = formatVnClock(value);
  return isSameDay(value, now) ? `${time} Hôm nay` : `${time} ${DAY_FORMAT.format(value)}`;
}

export function formatSubmittedTime(value: Date): string {
  return TIME_SECONDS_FORMAT.format(value);
}

/** "18:00" for a deadline today, otherwise "18:00 05/11". */
export function formatDeadline(value: Date, now: Date): string {
  const time = formatVnClock(value);
  return isSameDay(value, now) ? time : `${time} ${DAY_FORMAT.format(value)}`;
}
