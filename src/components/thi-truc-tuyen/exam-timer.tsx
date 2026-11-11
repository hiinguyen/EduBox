"use client";

import { formatMsClock } from "@/lib/format/time";
import { getRemainingAnnouncement, getRemainingMs } from "@/lib/thi-truc-tuyen/countdown";
import { Icon } from "@/components/ui/icon";
import { useExam } from "./exam-provider";
import { useServerNow } from "./use-server-now";

export function ExamTimer() {
  const { state, isTimeUp, submission } = useExam();
  const remainingMs = getRemainingMs(state.endsAt, useServerNow());
  const isSubmitted = submission.receipt !== null;

  return (
    <div className="flex items-center gap-space-sm rounded-xl bg-surface-container-low px-space-md py-2.5 shadow-sm">
      <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-primary/10 text-primary">
        <Icon name="timer" className="text-[24px]" />
      </div>
      <div className="flex flex-col">
        <span className="font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
          {isSubmitted ? "Trạng thái" : "Thời gian còn lại"}
        </span>
        <span
          className={`font-display text-headline-sm font-bold tracking-tight tabular-nums ${isTimeUp && !isSubmitted ? "text-error" : "text-primary"}`}
        >
          {isSubmitted ? "Đã nộp bài" : formatMsClock(remainingMs)}
        </span>
        {!isSubmitted && (
          <span role="status" className="sr-only">
            {getRemainingAnnouncement(remainingMs)}
          </span>
        )}
      </div>
    </div>
  );
}
