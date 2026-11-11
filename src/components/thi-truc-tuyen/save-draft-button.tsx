"use client";

import { Icon } from "@/components/ui/icon";
import { useExam } from "./exam-provider";

export function SaveDraftButton() {
  const { actions, isLocked } = useExam();

  return (
    <button
      type="button"
      disabled={isLocked}
      onClick={actions.save}
      className="flex items-center gap-1.5 rounded-lg bg-surface-container-high px-space-md py-2.5 font-label-md text-label-md text-on-surface shadow-sm transition-all hover:bg-surface-variant active:scale-95 disabled:opacity-40 disabled:active:scale-100"
    >
      <Icon name="save" className="text-[20px]" />
      <span className="hidden sm:inline">Tạm lưu</span>
      <span className="sr-only sm:hidden">Tạm lưu</span>
    </button>
  );
}
