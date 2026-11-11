import type { LessonChapter } from "./types";

export function findCurrentChapterId(
  chapters: readonly LessonChapter[],
  positionSeconds: number,
): string | null {
  const started = chapters.filter((chapter) => chapter.startSeconds <= positionSeconds);
  return started.at(-1)?.id ?? null;
}
