import { formatSecondsClock } from "@/lib/format/time";
import { findCurrentChapterId } from "@/lib/hoc-tap/chapters";
import type { LessonChapter } from "@/lib/hoc-tap/types";

interface LessonChaptersProps {
  readonly chapters: readonly LessonChapter[];
  readonly positionSeconds: number;
  readonly onSelect: (chapter: LessonChapter) => void;
}

export function LessonChapters({ chapters, positionSeconds, onSelect }: LessonChaptersProps) {
  const currentId = findCurrentChapterId(chapters, positionSeconds);

  return (
    <div className="flex flex-col gap-space-xs pt-space-xs">
      <h3 className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
        Mốc trọng tâm bài giảng
      </h3>
      <ul className="grid grid-cols-1 gap-space-sm sm:grid-cols-2 md:grid-cols-4">
        {chapters.map((chapter) => {
          const isCurrent = chapter.id === currentId;
          const clock = formatSecondsClock(chapter.startSeconds);
          return (
            <li key={chapter.id} className="min-w-0">
              <button
                type="button"
                aria-pressed={isCurrent}
                onClick={() => onSelect(chapter)}
                className={`flex w-full flex-col gap-0.5 rounded-lg p-2.5 text-left transition-colors ${
                  isCurrent
                    ? "bg-primary-fixed/60 ring-2 ring-primary/20"
                    : "bg-surface-container hover:bg-surface-container-high"
                }`}
              >
                <span
                  className={`font-label-sm text-label-sm font-bold ${
                    isCurrent ? "text-primary" : "text-on-surface-variant"
                  }`}
                >
                  {isCurrent ? `${clock} · Hiện tại` : clock}
                </span>
                <span className="w-full truncate font-body-sm text-body-sm font-medium text-on-surface">
                  {chapter.title}
                </span>
                <span
                  className={`font-label-sm text-label-sm ${
                    isCurrent ? "font-semibold text-primary" : "text-on-surface-variant"
                  }`}
                >
                  {isCurrent ? chapter.currentNote : chapter.note}
                </span>
              </button>
            </li>
          );
        })}
      </ul>
    </div>
  );
}
