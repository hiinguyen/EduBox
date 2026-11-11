import { MS_PER_SECOND } from "@/lib/format/time";
import { MAX_PERCENT } from "@/lib/format/percent";
import { MAX_CREDITED_SECONDS_PER_UPDATE } from "./constants";

export interface PreviousProgress {
  readonly positionSeconds: number;
  readonly updatedAt: Date;
}

export interface CreditInput {
  readonly previous: PreviousProgress | null;
  readonly positionSeconds: number;
  readonly now: Date;
}

/**
 * Seconds of study one progress save may add: the forward move since the last saved position,
 * capped per call and by the wall-clock time since that save, so seeking cannot fake hours.
 */
export function computeCreditedSeconds({ previous, positionSeconds, now }: CreditInput): number {
  const forward = Math.max(0, positionSeconds - (previous?.positionSeconds ?? 0));
  const elapsed = previous
    ? Math.max(0, Math.floor((now.getTime() - previous.updatedAt.getTime()) / MS_PER_SECOND))
    : MAX_CREDITED_SECONDS_PER_UPDATE;
  return Math.min(forward, MAX_CREDITED_SECONDS_PER_UPDATE, elapsed);
}

export interface CourseProgress {
  readonly currentLesson: number;
  readonly progressPercent: number;
}

/** `completedNumbers` holds the course position of each completed lesson (null when unnumbered). */
export function computeCourseProgress(
  completedNumbers: readonly (number | null)[],
  lessonCount: number,
): CourseProgress {
  const total = Math.max(1, lessonCount);
  const completed = Math.min(completedNumbers.length, total);
  const highest = Math.max(0, ...completedNumbers.map((number) => number ?? 0));
  return {
    currentLesson: Math.min(highest + 1, total),
    progressPercent: Math.round((completed / total) * MAX_PERCENT),
  };
}
