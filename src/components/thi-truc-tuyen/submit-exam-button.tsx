"use client";

import { useEffect, useRef } from "react";
import { Icon } from "@/components/ui/icon";
import { getProgress } from "@/lib/thi-truc-tuyen/progress";
import { useExam } from "./exam-provider";

const TITLE_ID = "submit-exam-title";
const DESCRIPTION_ID = "submit-exam-description";
const ERROR_ID = "submit-exam-error";

export function SubmitExamButton() {
  const { questions, state, submission } = useExam();
  const dialogRef = useRef<HTMLDialogElement>(null);
  const errorRef = useRef<HTMLParagraphElement>(null);
  const isPending = submission.phase === "pending";
  const progress = getProgress(
    questions.map((question) => question.id),
    state.answers,
    state.flaggedIds,
  );

  useEffect(() => {
    if (submission.errorMessage) errorRef.current?.focus();
  }, [submission.errorMessage]);

  const close = () => {
    if (!isPending) dialogRef.current?.close();
  };
  const confirm = async () => {
    const isAccepted = await submission.submit();
    if (isAccepted) dialogRef.current?.close();
  };

  return (
    <>
      <button
        type="button"
        onClick={() => dialogRef.current?.showModal()}
        className="flex shrink-0 items-center gap-1.5 whitespace-nowrap rounded-lg bg-primary-container px-space-lg py-2.5 font-label-md text-label-md text-on-primary shadow-md transition-all hover:bg-primary active:scale-95"
      >
        <Icon name="cloud_download" className="text-[20px]" />
        <span>Nộp bài thi</span>
      </button>
      <dialog
        ref={dialogRef}
        aria-labelledby={TITLE_ID}
        aria-describedby={DESCRIPTION_ID}
        onCancel={(event) => {
          if (isPending) event.preventDefault();
        }}
        onClick={(event) => {
          if (event.target === event.currentTarget) close();
        }}
        className="m-auto w-[calc(100%-2rem)] max-w-md rounded-2xl bg-surface-container-lowest p-space-lg text-on-surface shadow-level-3 backdrop:bg-inverse-surface/40 backdrop:backdrop-blur-sm"
      >
        <h2 id={TITLE_ID} className="font-headline-sm text-headline-sm">
          Nộp bài thi?
        </h2>
        <div
          id={DESCRIPTION_ID}
          className="mt-space-sm font-body-md text-body-md text-on-surface-variant"
        >
          <p>
            Bạn đã làm {progress.answered}/{progress.total} câu.
          </p>
          {progress.unanswered > 0 && <p>Còn {progress.unanswered} câu chưa làm.</p>}
          {progress.flagged > 0 && <p>Có {progress.flagged} câu đang được gắn cờ.</p>}
          <p>Sau khi nộp bạn không thể sửa đáp án.</p>
        </div>
        {submission.errorMessage && (
          <p
            id={ERROR_ID}
            ref={errorRef}
            role="alert"
            tabIndex={-1}
            className="mt-space-sm font-label-md text-label-md text-error focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-error"
          >
            {submission.errorMessage}
          </p>
        )}
        <div className="mt-space-lg flex flex-wrap justify-end gap-space-sm">
          <button
            type="button"
            disabled={isPending}
            onClick={close}
            className="rounded-lg bg-surface-container px-space-md py-2.5 font-label-md text-label-md text-on-surface transition-colors hover:bg-surface-container-high disabled:cursor-not-allowed disabled:opacity-40"
          >
            Tiếp tục làm bài
          </button>
          <button
            type="button"
            disabled={isPending}
            aria-busy={isPending}
            aria-describedby={submission.errorMessage ? ERROR_ID : undefined}
            onClick={confirm}
            className="rounded-lg bg-primary-container px-space-md py-2.5 font-label-md text-label-md text-on-primary transition-colors hover:bg-primary disabled:cursor-not-allowed disabled:opacity-40"
          >
            {isPending
              ? "Đang nộp bài..."
              : submission.errorMessage
                ? "Thử nộp lại"
                : "Xác nhận nộp bài"}
          </button>
        </div>
      </dialog>
    </>
  );
}
