import { Icon } from "@/components/ui/icon";
import { Pill } from "@/components/ui/pill";
import { SectionPanel } from "@/components/ui/section-panel";
import type { ActivityEntry, ActivityTone } from "@/lib/phu-huynh/types";

const MARKER_TONE_CLASS: Readonly<Record<ActivityTone, string>> = {
  primary: "bg-primary text-on-primary",
  secondary: "bg-secondary text-on-secondary",
  neutral: "bg-surface-variant text-primary",
};

function LiveBadge() {
  return (
    <span className="flex shrink-0 items-center gap-1 rounded-full bg-primary-fixed px-2 py-0.5 font-label-sm text-label-sm text-primary">
      <span aria-hidden="true" className="h-1.5 w-1.5 animate-pulse rounded-full bg-primary" />
      Cập nhật liên tục
    </span>
  );
}

function ActivityItem({ entry }: { readonly entry: ActivityEntry }) {
  return (
    <li className="relative flex flex-col gap-1">
      <span
        aria-hidden="true"
        className={`absolute -left-6 top-1 flex h-5 w-5 items-center justify-center rounded-full ring-4 ring-surface-container-lowest ${MARKER_TONE_CLASS[entry.tone]}`}
      >
        <Icon name={entry.icon} className="text-[12px]" />
      </span>
      <div className="flex flex-wrap items-center justify-between gap-x-space-sm">
        <h3 className="font-label-md text-label-md font-semibold text-on-surface">{entry.title}</h3>
        <span className="font-label-sm text-label-sm text-outline">{entry.timeLabel}</span>
      </div>
      <p className="font-body-sm text-body-sm text-on-surface-variant">
        {entry.description.map((segment) =>
          segment.isEmphasis ? (
            <strong key={segment.text} className="font-semibold text-primary">
              {segment.text}
            </strong>
          ) : (
            <span key={segment.text}>{segment.text}</span>
          ),
        )}
      </p>
      <ul className="mt-1 flex flex-wrap gap-2">
        {entry.tags.map((tag) => (
          <li key={tag.label}>
            <Pill tone={tag.tone} className="rounded!">
              {tag.label}
            </Pill>
          </li>
        ))}
      </ul>
    </li>
  );
}

interface ActivityLogProps {
  readonly entries: readonly ActivityEntry[];
}

export function ActivityLog({ entries }: ActivityLogProps) {
  return (
    <SectionPanel
      icon="history_edu"
      iconTone="secondary"
      title="Nhật ký học tập theo thời gian thực"
      aside={<LiveBadge />}
    >
      {entries.length === 0 ? (
        <p className="font-body-sm text-body-sm text-on-surface-variant">
          Chưa có hoạt động học tập nào gần đây.
        </p>
      ) : (
        <ol className="relative flex flex-col gap-space-md pl-6 before:absolute before:bottom-3 before:left-2.5 before:top-3 before:w-0.5 before:bg-surface-container-high before:content-['']">
          {entries.map((entry) => (
            <ActivityItem key={entry.id} entry={entry} />
          ))}
        </ol>
      )}
    </SectionPanel>
  );
}
