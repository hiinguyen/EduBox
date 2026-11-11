import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import type { EffortHighlight } from "@/lib/phu-huynh/types";

interface EffortHighlightCardProps {
  readonly effort: EffortHighlight;
}

export function EffortHighlightCard({ effort }: EffortHighlightCardProps) {
  return (
    <Card
      as="section"
      aria-label="Ghi nhận nỗ lực tuần"
      className="flex flex-col items-center gap-space-md sm:flex-row"
    >
      <div
        aria-hidden="true"
        className="flex h-32 w-full shrink-0 items-center justify-center rounded-lg bg-linear-to-br from-primary-fixed to-secondary-fixed sm:w-44"
      >
        <Icon name="auto_stories" className="text-[48px] text-primary" />
      </div>
      <div className="flex flex-col gap-1">
        <p className="flex items-center gap-1 font-label-sm text-label-sm text-primary">
          <Icon name="celebration" className="text-[16px]" />
          <span>{effort.eyebrow}</span>
        </p>
        <h2 className="font-headline-sm text-headline-sm text-on-surface">{effort.title}</h2>
        <p className="font-body-sm text-body-sm text-on-surface-variant">{effort.body}</p>
      </div>
    </Card>
  );
}
