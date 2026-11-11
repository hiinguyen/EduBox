import { Icon } from "@/components/ui/icon";
import { ProgressBar } from "@/components/ui/progress-bar";
import type { Tone } from "@/lib/ui/tone";
import type { StatDetail, StatId, WeeklyStat } from "@/lib/phu-huynh/types";

interface StatStyle {
  readonly iconBox: string;
  readonly value: string;
  readonly barTone: Tone;
}

const STAT_STYLE: Readonly<Record<StatId, StatStyle>> = {
  "online-time": {
    iconBox: "bg-primary-fixed text-primary",
    value: "text-primary",
    barTone: "primary",
  },
  lectures: {
    iconBox: "bg-secondary-fixed text-secondary",
    value: "text-on-surface",
    barTone: "secondary",
  },
  "average-score": {
    iconBox: "bg-tertiary-fixed text-tertiary",
    value: "text-tertiary",
    barTone: "tertiary",
  },
  "ai-questions": {
    iconBox: "bg-surface-container-high text-secondary",
    value: "text-secondary",
    barTone: "secondary",
  },
};

const DETAIL_ROW = "flex items-center gap-1.5 font-label-sm text-label-sm";

function StatDetailRow({ detail }: { readonly detail: StatDetail }) {
  switch (detail.kind) {
    case "trend":
      return (
        <div className={`${DETAIL_ROW} text-tertiary`}>
          <Icon name="trending_up" className="text-[16px]" />
          <span>{detail.text}</span>
        </div>
      );
    case "verified":
      return (
        <div className={`${DETAIL_ROW} text-on-surface-variant`}>
          <Icon name="check_circle" className="text-[16px] text-tertiary" />
          <span>
            {detail.prefix}
            <strong className="font-semibold text-tertiary">{detail.emphasis}</strong>
          </span>
        </div>
      );
    case "badge":
      return (
        <div
          className={`${DETAIL_ROW} w-max rounded bg-secondary-fixed/50 px-2 py-0.5 text-on-secondary-fixed-variant`}
        >
          <Icon name="star" className="text-[14px]" />
          <span>{detail.text}</span>
        </div>
      );
    case "note":
      return (
        <div className={`${DETAIL_ROW} text-on-surface-variant`}>
          <Icon name="menu_book" className="text-[16px]" />
          <span>{detail.text}</span>
        </div>
      );
    default: {
      const unreachable: never = detail;
      return unreachable;
    }
  }
}

function StatCard({ stat }: { readonly stat: WeeklyStat }) {
  const style = STAT_STYLE[stat.id];
  return (
    <li className="flex flex-col justify-between rounded-xl bg-surface-container-lowest p-space-md shadow-sm transition-all hover:shadow-md">
      <div className="mb-space-sm flex items-start justify-between gap-space-xs">
        <span className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
          {stat.label}
        </span>
        <div
          className={`flex h-9 w-9 shrink-0 items-center justify-center rounded-lg ${style.iconBox}`}
        >
          <Icon name={stat.icon} className="text-[20px]" />
        </div>
      </div>
      <div>
        <p className="mb-1 flex items-baseline gap-2">
          <span className={`font-headline-lg text-headline-lg ${style.value}`}>{stat.value}</span>
          <span className="font-body-md text-body-md text-on-surface-variant">{stat.unit}</span>
        </p>
        <StatDetailRow detail={stat.detail} />
      </div>
      <ProgressBar
        value={stat.progressPercent}
        label={stat.label}
        tone={style.barTone}
        className="mt-3"
      />
    </li>
  );
}

interface StatCardsProps {
  readonly stats: readonly WeeklyStat[];
}

export function StatCards({ stats }: StatCardsProps) {
  return (
    <section aria-label="Tổng kết tuần">
      <ul className="grid grid-cols-1 gap-space-md sm:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <StatCard key={stat.id} stat={stat} />
        ))}
      </ul>
    </section>
  );
}
