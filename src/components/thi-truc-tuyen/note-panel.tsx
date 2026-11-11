"use client";

import { MAX_NOTE_LENGTH } from "@/lib/thi-truc-tuyen/draft";
import type { Question } from "@/lib/thi-truc-tuyen/types";
import { useExam } from "./exam-provider";

interface NotePanelProps {
  readonly question: Question;
}

export function NotePanel({ question }: NotePanelProps) {
  const { state, actions } = useExam();
  const textareaId = `note-${question.id}`;

  return (
    <div className="flex flex-col gap-space-md rounded-xl bg-surface-container-low p-space-md">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <label
          htmlFor={textareaId}
          className="font-label-md text-label-md font-bold text-on-surface"
        >
          Nháp lời giải chi tiết cho Câu {question.number}
        </label>
        <span className="font-label-sm text-label-sm text-on-surface-variant">
          Định dạng hỗ trợ: Ảnh chụp (.jpg, .png) hoặc Gõ công thức Math
        </span>
      </div>
      <textarea
        id={textareaId}
        maxLength={MAX_NOTE_LENGTH}
        value={state.notes[question.id] ?? ""}
        onChange={(event) => actions.setNote(question.id, event.target.value)}
        placeholder="Gõ công thức hoặc suy luận: Ví dụ: g'(x) = 2(x - 1).f'(x^2 - 2x + m)..."
        className="h-28 w-full resize-none rounded-lg bg-surface-container-lowest p-3 font-body-sm text-body-sm text-on-surface shadow-sm focus:outline-none focus:ring-2 focus:ring-primary"
      />
    </div>
  );
}
