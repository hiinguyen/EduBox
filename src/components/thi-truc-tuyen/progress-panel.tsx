"use client";

import { useId, useState } from "react";
import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import { ProgressBar } from "@/components/ui/progress-bar";
import { getProgress } from "@/lib/thi-truc-tuyen/progress";
import { useExam } from "./exam-provider";
import { QuestionGrid } from "./question-grid";

interface LegendItem {
  readonly dotClassName: string;
  readonly label: string;
  readonly count: number;
}

export function ProgressPanel() {
  const { questions, state } = useExam();
  const [isExpanded, setIsExpanded] = useState(false);
  const gridId = useId();
  const progress = getProgress(
    questions.map((question) => question.id),
    state.answers,
    state.flaggedIds,
  );
  const legend: readonly LegendItem[] = [
    { dotClassName: "bg-primary-container", label: "Đã làm", count: progress.answered },
    { dotClassName: "bg-secondary-container", label: "Gắn cờ", count: progress.flagged },
    { dotClassName: "bg-surface-container-high", label: "Chưa làm", count: progress.unanswered },
  ];

  return (
    <Card
      as="section"
      aria-label="Tiến độ bài thi"
      className="flex flex-col gap-space-md p-space-md"
    >
      <div className="flex items-center justify-between">
        <h2 className="font-headline-sm text-label-md font-semibold text-on-surface">
          Tiến độ bài thi
        </h2>
        <span className="rounded-full bg-surface-container-high px-2 py-0.5 font-label-sm text-label-sm font-bold text-primary">
          {progress.answered} / {progress.total}
        </span>
      </div>
      <ProgressBar value={progress.percent} label="Số câu đã làm" className="h-2.5" />
      <ul className="grid grid-cols-3 gap-1 pt-1 font-label-sm text-label-sm text-on-surface-variant">
        {legend.map((item) => (
          <li key={item.label} className="flex items-center gap-1.5">
            <span
              className={`h-3 w-3 shrink-0 rounded-full ${item.dotClassName}`}
              aria-hidden="true"
            />
            <span>
              {item.label} ({item.count})
            </span>
          </li>
        ))}
      </ul>
      <button
        type="button"
        aria-expanded={isExpanded}
        aria-controls={gridId}
        onClick={() => setIsExpanded((value) => !value)}
        className="flex items-center justify-between rounded-lg bg-surface-container px-space-md py-2 font-label-md text-label-md text-on-surface lg:hidden"
      >
        Danh sách câu hỏi
        <Icon name={isExpanded ? "expand_less" : "expand_more"} className="text-[20px]" />
      </button>
      <div
        id={gridId}
        className={`flex-col gap-space-md border-t border-surface-container-high pt-space-md lg:flex ${isExpanded ? "flex" : "hidden"}`}
      >
        <QuestionGrid />
      </div>
    </Card>
  );
}
