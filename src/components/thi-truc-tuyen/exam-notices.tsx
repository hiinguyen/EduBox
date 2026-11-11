"use client";

import { useEffect, useRef, type ReactNode } from "react";
import { Icon } from "@/components/ui/icon";
import { useExam } from "./exam-provider";

type NoticeTone = "error" | "success";

interface NoticeProps {
  readonly role: "alert" | "status";
  readonly tone?: NoticeTone;
  readonly icon: string;
  readonly title: string;
  readonly shouldFocus?: boolean;
  readonly action?: ReactNode;
  readonly children: ReactNode;
}

const TONE_CLASS: Readonly<Record<NoticeTone, string>> = {
  error: "bg-error-container text-on-error-container",
  success: "bg-tertiary-fixed text-on-tertiary-fixed",
};

function Notice({ role, tone = "error", icon, title, shouldFocus, action, children }: NoticeProps) {
  const ref = useRef<HTMLDivElement>(null);

  useEffect(() => {
    if (shouldFocus) ref.current?.focus();
  }, [shouldFocus]);

  return (
    <div
      ref={ref}
      role={role}
      tabIndex={shouldFocus ? -1 : undefined}
      className={`flex flex-wrap items-start gap-space-sm rounded-xl p-space-md shadow-sm focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary ${TONE_CLASS[tone]}`}
    >
      <Icon name={icon} className="text-[22px]" />
      <div className="flex min-w-0 flex-1 flex-col gap-1">
        <p className="font-label-md text-label-md font-bold">{title}</p>
        <p className="font-body-sm text-body-sm">{children}</p>
      </div>
      {action}
    </div>
  );
}

function RetryButton({ onClick }: { onClick: () => void }) {
  return (
    <button
      type="button"
      onClick={onClick}
      className="rounded-lg bg-error px-space-md py-1.5 font-label-md text-label-md text-on-error transition-opacity hover:opacity-90"
    >
      Thử nộp lại
    </button>
  );
}

function SubmittedNotice() {
  const { submission, isTimeUp } = useExam();
  const { receipt, isFresh } = submission;
  if (!receipt) return null;
  const detail = receipt.isPendingReview
    ? "Giáo viên sẽ chấm bài và thông báo kết quả cho bạn."
    : "Phần trắc nghiệm đã được chấm tự động.";
  const isExpired = receipt.status === "EXPIRED";
  return (
    <Notice
      role="status"
      tone="success"
      icon="task_alt"
      title={isExpired || isTimeUp ? "Hết giờ - bài làm đã được nộp" : "Đã nộp bài"}
      shouldFocus={isFresh}
    >
      Bài làm của bạn đã được ghi nhận và không thể thay đổi. {detail}
    </Notice>
  );
}

export function ExamNotices() {
  const { isTimeUp, draftStatus, sync, submission } = useExam();
  const isOver = submission.receipt !== null;
  const hasSubmitFailed = isTimeUp && !isOver && submission.errorMessage !== null;

  return (
    <>
      <SubmittedNotice />
      {isTimeUp && !isOver && (
        <Notice
          role="alert"
          icon="timer_off"
          title="Hết giờ"
          action={
            hasSubmitFailed ? <RetryButton onClick={() => void submission.submit()} /> : undefined
          }
        >
          {hasSubmitFailed
            ? submission.errorMessage
            : "Thời gian làm bài đã kết thúc. Bài của bạn đang được nộp tự động."}
        </Notice>
      )}
      {!isOver && sync.problem && (
        <Notice role="alert" icon="cloud_off" title="Chưa lưu được bài lên máy chủ">
          {sync.problem.message}
        </Notice>
      )}
      {!isOver && draftStatus.hasStorageFailed && (
        <Notice role="alert" icon="warning" title="Không thể lưu nháp trên thiết bị này">
          Đáp án chưa được lưu lại. Hãy giữ nguyên trang này và bấm Tạm lưu để thử lại.
        </Notice>
      )}
      {!isOver && draftStatus.isOpenInAnotherTab && (
        <Notice role="status" icon="tab" title="Bài đang mở ở tab khác">
          Hãy làm bài ở một tab duy nhất để đáp án không bị ghi đè lẫn nhau.
        </Notice>
      )}
    </>
  );
}
