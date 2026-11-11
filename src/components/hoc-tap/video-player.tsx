import { Icon } from "@/components/ui/icon";
import type { FeaturedLesson } from "@/lib/hoc-tap/types";
import { ComingSoonButton } from "./coming-soon-button";
import { VideoControls } from "./video-controls";

interface VideoPlayerProps {
  readonly lesson: FeaturedLesson;
  readonly positionSeconds: number;
}

function VideoTopBar({ lesson }: { readonly lesson: FeaturedLesson }) {
  return (
    <div className="absolute inset-x-0 top-0 flex items-center justify-between bg-gradient-to-b from-black/80 via-black/30 to-transparent p-space-md text-on-primary">
      <div className="flex min-w-0 items-center gap-space-sm">
        <span className="rounded bg-primary-container px-2 py-0.5 font-label-sm text-label-sm font-semibold tracking-wide text-on-primary">
          ĐANG PHÁT
        </span>
        <span className="truncate font-label-md text-label-md">{lesson.title}</span>
      </div>
      <div className="flex items-center gap-2">
        {lesson.quality ? (
          <span className="rounded bg-black/40 px-2 py-1 font-label-sm text-label-sm backdrop-blur-sm">
            {lesson.quality}
          </span>
        ) : null}
        <ComingSoonButton label="Cài đặt video" className="rounded p-1">
          <Icon name="tune" className="text-[20px]" />
        </ComingSoonButton>
      </div>
    </div>
  );
}

export function VideoPlayer({ lesson, positionSeconds }: VideoPlayerProps) {
  return (
    <div className="relative aspect-video w-full overflow-hidden bg-inverse-surface">
      <div
        aria-hidden="true"
        className="absolute inset-0 flex items-center justify-center bg-gradient-to-br from-inverse-surface via-on-primary-fixed to-primary opacity-80"
      >
        <Icon name="function" className="text-[160px] text-white/10" />
      </div>
      <VideoTopBar lesson={lesson} />
      <ComingSoonButton
        label="Phát video"
        className="absolute inset-0 m-auto flex h-16 w-16 items-center justify-center rounded-full bg-primary/90 text-on-primary shadow-lg backdrop-blur-sm"
      >
        <Icon name="play_arrow" filled className="text-[36px]" />
      </ComingSoonButton>
      <VideoControls lesson={lesson} positionSeconds={positionSeconds} />
    </div>
  );
}
