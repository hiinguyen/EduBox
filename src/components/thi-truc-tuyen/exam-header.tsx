import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import type { ExamInfo } from "@/lib/thi-truc-tuyen/types";
import { ExamActionButtons } from "./exam-action-buttons";
import { ExamTimer } from "./exam-timer";

interface ExamHeaderProps {
  readonly exam: ExamInfo;
  readonly questionCount: number;
}

interface MetaItem {
  readonly icon: string;
  readonly label: string;
}

export function ExamHeader({ exam, questionCount }: ExamHeaderProps) {
  const meta: readonly MetaItem[] = [
    { icon: "timelapse", label: `${exam.durationMinutes} phút` },
    { icon: "quiz", label: `${questionCount} câu hỏi` },
    { icon: "grade", label: `Điểm tối đa: ${exam.maxScore.toFixed(1)}` },
    { icon: "person", label: exam.teacherName },
  ];

  return (
    <Card
      as="header"
      className="flex w-full flex-col items-start justify-between gap-space-md shadow-md xl:flex-row xl:items-center"
    >
      <div className="flex max-w-3xl flex-col gap-space-xs">
        <div className="flex flex-wrap items-center gap-space-sm">
          <span className="rounded-full bg-primary-fixed px-2.5 py-1 font-label-sm text-label-sm text-on-primary-fixed">
            {exam.kindLabel}
          </span>
          <span className="flex items-center gap-1 rounded-full bg-tertiary-fixed/30 px-2 py-0.5 font-label-sm text-label-sm text-tertiary">
            <span className="h-2 w-2 animate-pulse rounded-full bg-tertiary" aria-hidden="true" />
            {exam.proctorStatus}
          </span>
        </div>
        <h1 className="font-headline-md text-headline-md tracking-tight text-on-surface">
          {exam.title}
        </h1>
        <ul className="flex flex-wrap items-center gap-x-space-md gap-y-1 font-label-md text-label-md text-on-surface-variant">
          {meta.map((item, index) => (
            <li key={item.icon} className="flex items-center gap-space-md">
              <span className="flex items-center gap-1">
                <Icon name={item.icon} className="text-[18px]" />
                {item.label}
              </span>
              {index < meta.length - 1 && (
                <span aria-hidden="true" className="text-outline-variant">
                  •
                </span>
              )}
            </li>
          ))}
        </ul>
      </div>
      <div className="flex w-full flex-wrap items-center justify-between gap-space-md xl:w-auto xl:justify-end">
        <ExamTimer />
        <ExamActionButtons />
      </div>
    </Card>
  );
}
