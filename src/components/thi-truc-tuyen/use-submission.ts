import { useCallback, useRef, useState } from "react";
import { submitAttempt } from "@/lib/thi-truc-tuyen/actions";
import type { SaveItem } from "@/lib/thi-truc-tuyen/sync";
import type { SubmissionReceipt } from "@/lib/thi-truc-tuyen/types";

export type SubmitPhase = "idle" | "pending" | "error";

export interface SubmissionControl {
  readonly receipt: SubmissionReceipt | null;
  /** True only when this browser session performed the submit, so focus can move to the result. */
  readonly isFresh: boolean;
  readonly phase: SubmitPhase;
  readonly errorMessage: string | null;
  /** Submits once at a time; resolves to whether the server accepted the submission. */
  readonly submit: () => Promise<boolean>;
}

interface SubmissionInput {
  readonly attemptId: string;
  readonly initialReceipt: SubmissionReceipt | null;
  readonly getPendingItems: () => readonly SaveItem[];
  readonly onSubmitted: () => void;
}

const NETWORK_MESSAGE =
  "Chưa nộp được bài do lỗi kết nối. Đáp án vẫn được giữ lại, hãy thử nộp lại.";

export function useSubmission(input: SubmissionInput): SubmissionControl {
  const { attemptId, getPendingItems, onSubmitted } = input;
  const [receipt, setReceipt] = useState(input.initialReceipt);
  const [isFresh, setIsFresh] = useState(false);
  const [phase, setPhase] = useState<SubmitPhase>("idle");
  const [errorMessage, setErrorMessage] = useState<string | null>(null);
  const isRunning = useRef(false);

  const submit = useCallback(async (): Promise<boolean> => {
    if (isRunning.current) return false;
    isRunning.current = true;
    setPhase("pending");
    setErrorMessage(null);
    const result = await submitAttempt({ attemptId, answers: getPendingItems() }).catch(() => null);
    isRunning.current = false;
    if (!result?.ok) {
      setPhase("error");
      setErrorMessage(result ? result.error.message : NETWORK_MESSAGE);
      return false;
    }
    setReceipt(result.data.receipt);
    setIsFresh(true);
    setPhase("idle");
    onSubmitted();
    return true;
  }, [attemptId, getPendingItems, onSubmitted]);

  return { receipt, isFresh, phase, errorMessage, submit };
}
