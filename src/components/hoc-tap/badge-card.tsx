import { Icon } from "@/components/ui/icon";
import type { BadgeProgress } from "@/lib/hoc-tap/types";

interface BadgeCardProps {
  readonly badge: BadgeProgress;
}

export function BadgeCard({ badge }: BadgeCardProps) {
  return (
    <aside className="flex items-center gap-space-md rounded-xl bg-gradient-to-br from-primary-fixed to-secondary-fixed/50 p-space-md">
      <div className="flex h-12 w-12 flex-shrink-0 items-center justify-center rounded-xl bg-surface-container-lowest text-primary shadow-sm">
        <Icon name="military_tech" filled className="text-[28px]" />
      </div>
      <div>
        <h2 className="font-label-md text-label-md font-bold text-on-primary-fixed">
          {badge.title}
        </h2>
        <p className="font-label-sm text-label-sm text-on-primary-fixed-variant">
          {badge.description}
        </p>
      </div>
    </aside>
  );
}
