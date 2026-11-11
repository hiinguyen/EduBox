"use client";

import { useState } from "react";
import { Icon } from "@/components/ui/icon";
import { DEFAULT_ERROR_MESSAGES } from "@/lib/server/action-result";
import { acknowledgeNoteAction } from "@/lib/phu-huynh/actions";

interface AcknowledgeNoteButtonProps {
  readonly noteId: string;
}

export function AcknowledgeNoteButton({ noteId }: AcknowledgeNoteButtonProps) {
  const [isPending, setIsPending] = useState(false);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleClick = async () => {
    setIsPending(true);
    setErrorMessage(null);
    try {
      const result = await acknowledgeNoteAction({ noteId });
      if (!result.ok) setErrorMessage(result.error.message);
    } catch {
      setErrorMessage(DEFAULT_ERROR_MESSAGES.INTERNAL);
    } finally {
      setIsPending(false);
    }
  };

  return (
    <span className="flex flex-col items-end gap-1">
      <button
        type="button"
        disabled={isPending}
        onClick={() => void handleClick()}
        className="flex items-center gap-1 rounded font-label-sm text-label-sm font-semibold text-primary hover:underline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary disabled:opacity-60"
      >
        <Icon name="done" className="text-[16px]" /> Xác nhận đã đọc
      </button>
      {errorMessage ? (
        <span role="alert" className="text-error">
          {errorMessage}
        </span>
      ) : null}
    </span>
  );
}
