export const MS_PER_SECOND = 1_000;
const SECONDS_PER_MINUTE = 60;
export const MS_PER_MINUTE = SECONDS_PER_MINUTE * MS_PER_SECOND;
export const MS_PER_HOUR = 60 * MS_PER_MINUTE;
export const MS_PER_DAY = 24 * MS_PER_HOUR;
const PAD_WIDTH = 2;

export function padTwo(value: number): string {
  return String(value).padStart(PAD_WIDTH, "0");
}

function toClock(totalSeconds: number): string {
  const minutes = Math.floor(totalSeconds / SECONDS_PER_MINUTE);
  return `${padTwo(minutes)}:${padTwo(totalSeconds % SECONDS_PER_MINUTE)}`;
}

/** Formats a duration in seconds as mm:ss, flooring fractions and clamping negatives to zero. */
export function formatSecondsClock(seconds: number): string {
  return toClock(Math.max(0, Math.floor(seconds)));
}

/** Formats a duration in milliseconds as mm:ss, rounding partial seconds up (countdown style). */
export function formatMsClock(ms: number): string {
  return toClock(Math.ceil(Math.max(0, ms) / MS_PER_SECOND));
}
