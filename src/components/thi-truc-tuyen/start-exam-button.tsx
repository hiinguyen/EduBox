"use client";

import { useRouter } from "next/navigation";
import { useState, useTransition } from "react";
import { Icon } from "@/components/ui/icon";
import { startAttempt } from "@/lib/thi-truc-tuyen/actions";
import { NETWORK_MESSAGE } from "@/lib/thi-truc-tuyen/exam-errors";

interface StartExamButtonProps {
  readonly assessmentId: string;
  readonly isDisabled: boolean;
}

/** The only way to begin an exam: the server creates the attempt and fixes the deadline. */
export function StartExamButton({ assessmentId, isDisabled }: StartExamButtonProps) {
  const router = useRouter();
  const [isRefreshing, startRefresh] = useTransition();
  const [isStarting, setIsStarting] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const isBusy = isStarting || isRefreshing;

  const start = async () => {
    setIsStarting(true);
    setErrorMessage(null);
    const result = await startAttempt({ assessmentId }).catch(() => null);
    setIsStarting(false);
    if (!result?.ok) {
      setErrorMessage(result ? result.error.message : NETWORK_MESSAGE);
      return;
    }
    startRefresh(() => router.refresh());
  };

  return (
    <div className="flex flex-col gap-space-sm">
      <button
        type="button"
        onClick={() => void start()}
        disabled={isDisabled || isBusy}
        className="flex w-full items-center justify-center gap-2 rounded-lg bg-primary-container px-space-lg py-3 font-label-md text-label-md text-on-primary shadow-md transition-all hover:bg-primary active:scale-95 disabled:cursor-not-allowed disabled:opacity-60 sm:w-auto sm:self-start"
      >
        <Icon name="play_arrow" className="text-[20px]" />
        {isBusy ? "Đang bắt đầu..." : "Bắt đầu làm bài"}
      </button>
      {errorMessage && (
        <p role="alert" className="font-body-sm text-body-sm text-error">
          {errorMessage}
        </p>
      )}
    </div>
  );
}
