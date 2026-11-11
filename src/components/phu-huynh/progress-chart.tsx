import { useId } from "react";
import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import type { ProgressReport } from "@/lib/phu-huynh/types";
import { TONE_TEXT_CLASS } from "@/lib/ui/tone";
import { ScoreChart } from "./score-chart";

interface ProgressChartProps {
  readonly progress: ProgressReport | null;
}

export function ProgressChart({ progress }: ProgressChartProps) {
  const titleId = useId();
  if (!progress) {
    return (
      <Card as="section" aria-labelledby={titleId} className="flex flex-col gap-space-sm">
        <div className="flex items-center gap-space-xs">
          <Icon name="show_chart" className="text-[22px] text-primary" />
          <h2 id={titleId} className="font-headline-sm text-headline-sm text-on-surface">
            Biểu đồ tiến độ & Phong độ học tập
          </h2>
        </div>
        <p className="font-body-sm text-body-sm text-on-surface-variant">
          Chưa có điểm kiểm tra để hiển thị biểu đồ.
        </p>
      </Card>
    );
  }
  return (
    <Card as="section" aria-labelledby={titleId} className="flex flex-col gap-space-md">
      <div className="flex flex-col items-start justify-between gap-space-sm sm:flex-row sm:items-center">
        <div>
          <div className="flex items-center gap-space-xs">
            <Icon name="show_chart" className="text-[22px] text-primary" />
            <h2 id={titleId} className="font-headline-sm text-headline-sm text-on-surface">
              Biểu đồ tiến độ & Phong độ học tập
            </h2>
          </div>
          <p className="mt-0.5 font-body-sm text-body-sm text-on-surface-variant">
            {progress.subtitle}
          </p>
        </div>
        <ul
          aria-label="Chú thích môn học"
          className="flex shrink-0 items-center gap-space-xs rounded-lg bg-surface-container-low p-1"
        >
          {progress.series.map((series) => (
            <li
              key={series.id}
              className={`flex items-center gap-1 px-2 py-1 font-label-sm text-label-sm ${TONE_TEXT_CLASS[series.tone]}`}
            >
              <span
                aria-hidden="true"
                className={`inline-block h-2.5 w-2.5 rounded-full bg-current`}
              />
              {series.label}
            </li>
          ))}
        </ul>
      </div>
      <ScoreChart progress={progress} />
      <p className="flex items-center gap-space-xs rounded-lg bg-surface-container p-space-sm font-body-sm text-body-sm leading-snug text-on-surface">
        <Icon name="insights" className="text-[20px] text-primary" />
        <span>
          <strong>{progress.insight.lead}</strong> {progress.insight.body}
        </span>
      </p>
    </Card>
  );
}
