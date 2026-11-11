import { MS_PER_MINUTE } from "@/lib/format/time";

/** The deadline is the earlier of the full duration and the exam's due date. */
export function computeEndsAt(now: Date, durationMinutes: number, dueAt: Date | null): Date {
  const byDuration = now.getTime() + durationMinutes * MS_PER_MINUTE;
  return new Date(dueAt ? Math.min(byDuration, dueAt.getTime()) : byDuration);
}
