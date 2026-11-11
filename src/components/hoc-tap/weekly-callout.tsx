import { Icon } from "@/components/ui/icon";
import type { WeeklySummary } from "@/lib/hoc-tap/types";
import { ProgressRing } from "./progress-ring";

interface WeeklyCalloutProps {
  readonly summary: WeeklySummary;
}

export function WeeklyCallout({ summary }: WeeklyCalloutProps) {
  return (
    <div className="flex flex-col items-stretch gap-space-md rounded-xl bg-surface-container-low p-space-md sm:flex-row sm:items-center">
      <div className="flex min-w-[200px] items-center gap-space-md">
        <ProgressRing percent={summary.progressPercent} />
        <div className="flex flex-col">
          <span className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
            Tiến độ tuần
          </span>
          <span className="font-label-md text-label-md font-semibold text-on-surface">
            {summary.goalDeltaPercent > 0
              ? `Tăng ${summary.goalDeltaPercent}% so với tuần trước`
              : "Giữ vững nhịp học mỗi ngày"}
          </span>
        </div>
      </div>
      <div aria-hidden="true" className="hidden h-10 w-px bg-outline-variant/30 sm:block" />
      <dl className="grid min-w-[200px] grid-cols-2 gap-space-md">
        <div className="flex flex-col">
          <dt className="flex items-center gap-1 font-label-sm text-label-sm text-on-surface-variant">
            <Icon name="schedule" className="text-[16px] text-primary" />
            Đã tích lũy
          </dt>
          <dd className="font-headline-sm text-headline-sm font-bold text-on-surface">
            {summary.hoursLogged}
            <span className="font-label-sm text-label-sm font-normal text-on-surface-variant">
              {" "}
              / {summary.hoursTarget}h
            </span>
          </dd>
        </div>
        <div className="flex flex-col">
          <dt className="flex items-center gap-1 font-label-sm text-label-sm text-on-surface-variant">
            <Icon name="assignment_late" className="text-[16px] text-error" />
            Đến hạn
          </dt>
          <dd className="font-headline-sm text-headline-sm font-bold text-error">
            {summary.dueCount}
            <span className="font-label-sm text-label-sm font-normal text-on-surface-variant">
              {" "}
              bài
            </span>
          </dd>
        </div>
      </dl>
    </div>
  );
}
