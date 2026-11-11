import { Icon } from "@/components/ui/icon";
import { formatSecondsClock } from "@/lib/format/time";
import { findCurrentChapterId } from "@/lib/hoc-tap/chapters";
import { percentOf } from "@/lib/hoc-tap/timeline";
import type { FeaturedLesson } from "@/lib/hoc-tap/types";
import { ComingSoonButton } from "./coming-soon-button";

const MARKER_TOOLTIP_SEPARATOR = " - ";

interface VideoControlsProps {
  readonly lesson: FeaturedLesson;
  readonly positionSeconds: number;
}

interface VideoTimelineProps extends VideoControlsProps {
  readonly clock: string;
}

function VideoTimeline({ lesson, positionSeconds, clock }: VideoTimelineProps) {
  return (
    <div
      role="progressbar"
      aria-label="Tiến độ video"
      aria-valuemin={0}
      aria-valuemax={lesson.durationSeconds}
      aria-valuenow={positionSeconds}
      aria-valuetext={clock}
      className="relative flex h-2 w-full items-center rounded-full bg-white/20"
    >
      <div
        className="h-full rounded-full bg-primary-container"
        style={{ width: `${percentOf(positionSeconds, lesson.durationSeconds)}%` }}
      />
      {lesson.chapters.map((chapter) => (
        <span
          key={chapter.id}
          title={`${formatSecondsClock(chapter.startSeconds)}${MARKER_TOOLTIP_SEPARATOR}${chapter.title}`}
          className="absolute h-2 w-2 rounded-full bg-secondary-fixed ring-2 ring-inverse-surface"
          style={{ left: `${percentOf(chapter.startSeconds, lesson.durationSeconds)}%` }}
        />
      ))}
    </div>
  );
}

export function VideoControls({ lesson, positionSeconds }: VideoControlsProps) {
  const currentChapterId = findCurrentChapterId(lesson.chapters, positionSeconds);
  const chapterLabel = lesson.chapters.find((chapter) => chapter.id === currentChapterId)?.title;
  const clock = `${formatSecondsClock(positionSeconds)} / ${formatSecondsClock(lesson.durationSeconds)}`;

  return (
    <div className="absolute inset-x-0 bottom-0 flex flex-col gap-2 bg-gradient-to-t from-black/90 via-black/40 to-transparent p-space-md text-on-primary">
      <VideoTimeline lesson={lesson} positionSeconds={positionSeconds} clock={clock} />
      <div className="flex items-center justify-between pt-1 font-label-sm text-label-sm">
        <div className="flex items-center gap-space-md">
          <span>{clock}</span>
          <span aria-hidden="true" className="hidden text-white/60 sm:inline">
            |
          </span>
          <span className="hidden font-medium text-white/80 sm:inline">{chapterLabel}</span>
        </div>
        <div className="flex items-center gap-space-sm">
          <ComingSoonButton label="Phụ đề">
            <Icon name="subtitles" className="text-[20px]" />
          </ComingSoonButton>
          <ComingSoonButton label="Tốc độ phát">
            <Icon name="speed" className="text-[20px]" />
          </ComingSoonButton>
          <ComingSoonButton label="Toàn màn hình">
            <Icon name="fullscreen" className="text-[20px]" />
          </ComingSoonButton>
        </div>
      </div>
    </div>
  );
}
