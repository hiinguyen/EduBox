import type { FormEvent } from "react";
import { Icon } from "@/components/ui/icon";
import { ComingSoonButton } from "./coming-soon-button";

const SOLUTION_HINT_REQUEST = "Gợi ý phương pháp giải";
const ICON_BUTTON = "rounded-md p-1.5 text-outline";

interface TutorComposerProps {
  readonly draft: string;
  readonly error: string | null;
  readonly isPending: boolean;
  readonly onDraftChange: (draft: string) => void;
  readonly onSubmit: (event: FormEvent<HTMLFormElement>) => void;
  readonly onHintRequest: (request: string) => unknown;
}

export function TutorComposer({
  draft,
  error,
  isPending,
  onDraftChange,
  onSubmit,
  onHintRequest,
}: TutorComposerProps) {
  return (
    <form
      onSubmit={onSubmit}
      noValidate
      className="flex flex-col gap-space-sm bg-surface-container-lowest p-space-md"
    >
      <div className="relative flex items-center">
        <label htmlFor="tutor-input" className="sr-only">
          Câu trả lời hoặc thắc mắc của bạn
        </label>
        <input
          id="tutor-input"
          type="text"
          value={draft}
          onChange={(event) => onDraftChange(event.target.value)}
          placeholder="Nhập câu trả lời hoặc thắc mắc của bạn..."
          aria-invalid={error ? true : undefined}
          aria-describedby={error ? "tutor-error" : undefined}
          autoComplete="off"
          className="h-11 w-full rounded-lg bg-surface-container-low pl-3 pr-24 font-body-sm text-body-sm text-on-surface transition-all placeholder:text-outline focus:outline-none focus:ring-2 focus:ring-secondary/30 focus-visible:outline-none"
        />
        <div className="absolute right-1 flex items-center gap-0.5">
          <ComingSoonButton label="Gửi ảnh đề bài chụp từ camera" className={ICON_BUTTON}>
            <Icon name="add_a_photo" className="text-[20px]" />
          </ComingSoonButton>
          <ComingSoonButton label="Ghi âm giọng nói" className={ICON_BUTTON}>
            <Icon name="mic" className="text-[20px]" />
          </ComingSoonButton>
          <button
            type="submit"
            disabled={isPending}
            aria-label="Gửi tin nhắn"
            className="rounded-md bg-secondary p-1.5 text-on-secondary shadow-sm transition-colors hover:bg-secondary/90 disabled:cursor-not-allowed disabled:opacity-60"
          >
            <Icon name="send" className="text-[18px]" />
          </button>
        </div>
      </div>
      {error ? (
        <p id="tutor-error" role="alert" className="font-label-sm text-label-sm text-error">
          {error}
        </p>
      ) : null}
      <div className="flex items-center justify-between gap-space-sm font-label-sm text-label-sm text-on-surface-variant">
        <span className="flex items-center gap-1">
          <Icon name="lightbulb" className="text-[14px]" />
          Phím tắt: Enter để gửi phản hồi
        </span>
        <button
          type="button"
          disabled={isPending}
          onClick={() => onHintRequest(SOLUTION_HINT_REQUEST)}
          className="flex disabled:cursor-not-allowed disabled:opacity-60 items-center gap-0.5 rounded font-semibold text-secondary hover:underline"
        >
          <span>Gợi ý phương pháp giải</span>
          <Icon name="arrow_outward" className="text-[16px]" />
        </button>
      </div>
    </form>
  );
}
