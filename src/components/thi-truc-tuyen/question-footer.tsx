"use client";

import { Icon } from "@/components/ui/icon";
import { useExam } from "./exam-provider";
import type { SyncStatus } from "./use-server-sync";

const TIME_FORMAT = new Intl.DateTimeFormat("vi-VN", {
  hour: "2-digit",
  minute: "2-digit",
  second: "2-digit",
  hour12: false,
});

const NAV_BUTTON_CLASS =
  "flex items-center gap-2 rounded-lg px-space-lg py-2.5 font-label-md text-label-md shadow-sm transition-all active:scale-95 disabled:opacity-40 disabled:active:scale-100";

export function QuestionFooter() {
  const { questions, state, actions, isLocked, draftStatus, sync } = useExam();
  const previous = questions[state.currentIndex - 1];
  const next = questions[state.currentIndex + 1];

  return (
    <div className="mt-space-sm flex flex-wrap items-center justify-between gap-space-md border-t border-surface-container-high pt-space-md">
      <button
        type="button"
        disabled={!previous || isLocked}
        onClick={actions.previous}
        className={`${NAV_BUTTON_CLASS} bg-surface-container text-on-surface hover:bg-surface-container-high`}
      >
        <Icon name="arrow_back" className="text-[20px]" />
        <span>{previous ? `Câu trước (Câu ${previous.number})` : "Câu trước"}</span>
      </button>
      <p className="flex items-center gap-space-sm font-label-sm text-label-sm text-on-surface-variant">
        <SaveStatus
          savedAt={sync.savedAt ?? draftStatus.savedAt}
          hasStorageFailed={draftStatus.hasStorageFailed}
          syncStatus={sync.status}
          isLocked={isLocked}
        />
      </p>
      <button
        type="button"
        disabled={!next || isLocked}
        onClick={actions.next}
        className={`${NAV_BUTTON_CLASS} bg-primary-container text-on-primary hover:bg-primary`}
      >
        <span>{next ? `Câu tiếp theo (Câu ${next.number})` : "Câu tiếp theo"}</span>
        <Icon name="arrow_forward" className="text-[20px]" />
      </button>
    </div>
  );
}

interface SaveStatusProps {
  readonly savedAt: number | null;
  readonly hasStorageFailed: boolean;
  readonly syncStatus: SyncStatus;
  readonly isLocked: boolean;
}

function SaveStatus({ savedAt, hasStorageFailed, syncStatus, isLocked }: SaveStatusProps) {
  if (isLocked) return <span>Bài làm đã được khóa</span>;
  if (syncStatus === "error") {
    return (
      <>
        <Icon name="cloud_off" className="text-[16px] text-error" />
        <span className="text-error">Chưa lưu được lên máy chủ, đang thử lại</span>
      </>
    );
  }
  if (hasStorageFailed) {
    return (
      <>
        <Icon name="warning" className="text-[16px] text-error" />
        <span className="text-error">Không thể lưu nháp trên thiết bị này</span>
      </>
    );
  }
  if (syncStatus === "saving" || syncStatus === "pending") {
    return (
      <>
        <Icon name="sync" className="text-[16px] text-on-surface-variant" />
        <span>Đang lưu bài...</span>
      </>
    );
  }
  return (
    <>
      <Icon name="check" className="text-[16px] text-tertiary" />
      <span>
        {savedAt === null
          ? "Tự động lưu bài"
          : `Tự động lưu bài lúc ${TIME_FORMAT.format(savedAt)}`}
      </span>
    </>
  );
}
