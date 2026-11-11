"use client";

import { useState, useTransition } from "react";
import type { FormEvent } from "react";
import { formatSecondsClock } from "@/lib/format/time";
import { saveLessonNoteAction } from "@/lib/hoc-tap/actions";
import { NETWORK_ERROR_MESSAGE } from "@/lib/hoc-tap/chat-client";
import { MAX_NOTE_LENGTH } from "@/lib/hoc-tap/constants";
import type { LessonNote } from "@/lib/hoc-tap/types";

interface LessonNotesProps {
  readonly lessonId: string;
  readonly positionSeconds: number;
  readonly notes: readonly LessonNote[];
  readonly onSaved: (note: LessonNote) => void;
}

export function LessonNotes({ lessonId, positionSeconds, notes, onSaved }: LessonNotesProps) {
  const [body, setBody] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [isPending, startTransition] = useTransition();

  function handleSubmit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    startTransition(async () => {
      try {
        const result = await saveLessonNoteAction({ lessonId, atSeconds: positionSeconds, body });
        if (!result.ok) {
          setError(result.error.message);
          return;
        }
        setError(null);
        setBody("");
        onSaved(result.data);
      } catch {
        setError(NETWORK_ERROR_MESSAGE);
      }
    });
  }

  return (
    <div className="flex flex-col gap-space-sm rounded-xl bg-surface-container-low p-space-md">
      <form onSubmit={handleSubmit} noValidate className="flex flex-col gap-space-sm">
        <label
          htmlFor="lesson-note-input"
          className="font-label-md text-label-md font-semibold text-on-surface"
        >
          Ghi chú tại {formatSecondsClock(positionSeconds)}
        </label>
        <textarea
          id="lesson-note-input"
          value={body}
          onChange={(event) => setBody(event.target.value)}
          maxLength={MAX_NOTE_LENGTH}
          rows={3}
          aria-invalid={error ? true : undefined}
          aria-describedby={error ? "lesson-note-error" : undefined}
          placeholder="Ghi lại điều cần nhớ ở thời điểm này..."
          className="w-full resize-y rounded-lg bg-surface-container-lowest p-space-sm font-body-sm text-body-sm text-on-surface placeholder:text-outline focus-visible:outline-2 focus-visible:outline-secondary"
        />
        {error ? (
          <p id="lesson-note-error" role="alert" className="font-label-sm text-label-sm text-error">
            {error}
          </p>
        ) : null}
        <button
          type="submit"
          disabled={isPending}
          className="self-end rounded-lg bg-secondary px-space-md py-2 font-label-md text-label-md text-on-secondary shadow-sm transition-colors hover:bg-secondary/90 disabled:cursor-not-allowed disabled:opacity-60"
        >
          {isPending ? "Đang lưu..." : "Lưu ghi chú"}
        </button>
      </form>
      {notes.length > 0 ? (
        <ul aria-label="Ghi chú đã lưu" className="flex flex-col gap-1.5">
          {notes.map((note) => (
            <li
              key={note.id}
              className="flex gap-space-sm rounded-lg bg-surface-container-lowest p-space-sm font-body-sm text-body-sm text-on-surface"
            >
              <span className="shrink-0 font-label-sm text-label-sm font-bold text-primary">
                {formatSecondsClock(note.atSeconds)}
              </span>
              <span className="min-w-0 whitespace-pre-wrap break-words">{note.body}</span>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
