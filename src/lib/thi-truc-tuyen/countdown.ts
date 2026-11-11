import { MS_PER_MINUTE } from "../format/time";

export function getRemainingMs(endsAt: number, now: number): number {
  return Math.max(0, endsAt - now);
}

/** An end time of zero means the exam has not started yet, so it is never "up". */
export function isTimeUp(endsAt: number, now: number): boolean {
  return endsAt > 0 && now >= endsAt;
}

export function getRemainingAnnouncement(remainingMs: number): string {
  if (remainingMs <= 0) return "Đã hết giờ làm bài";
  return `Còn ${Math.ceil(remainingMs / MS_PER_MINUTE)} phút`;
}
