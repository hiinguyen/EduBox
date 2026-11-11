import { Avatar } from "@/components/ui/avatar";
import { Icon } from "@/components/ui/icon";
import { splitByHighlight } from "@/lib/hoc-tap/chat-session";
import type { ChatMessage } from "@/lib/hoc-tap/types";

interface HighlightedProps {
  readonly text: string;
  readonly highlight?: string;
  readonly highlightClass: string;
}

function Highlighted({ text, highlight, highlightClass }: HighlightedProps) {
  return splitByHighlight(text, highlight).map((part, index) =>
    part.isHighlight ? (
      <strong key={index} className={`font-mono ${highlightClass}`}>
        {part.text}
      </strong>
    ) : (
      <span key={index}>{part.text}</span>
    ),
  );
}

interface StudentBubbleProps {
  readonly message: ChatMessage;
  readonly studentName: string;
}

export function StudentBubble({ message, studentName }: StudentBubbleProps) {
  return (
    <div className="flex items-start justify-end gap-space-sm">
      <div className="max-w-[85%] rounded-2xl rounded-tr-none bg-primary p-space-md text-on-primary shadow-sm">
        <p className="break-words font-body-sm text-body-sm">
          <Highlighted
            text={message.text}
            highlight={message.highlight}
            highlightClass="text-primary-fixed"
          />
        </p>
        <span className="mt-1 block text-right font-label-sm text-label-sm text-primary-fixed/80">
          {message.time}
        </span>
      </div>
      <Avatar name={studentName} size="sm" tone="primary" />
    </div>
  );
}

interface AssistantBubbleProps {
  readonly message: ChatMessage;
  readonly onSuggestion: (suggestion: string) => unknown;
}

export function AssistantBubble({ message, onSuggestion }: AssistantBubbleProps) {
  return (
    <div className="flex items-start gap-space-sm">
      <div
        aria-hidden="true"
        className="flex h-8 w-8 flex-shrink-0 items-center justify-center rounded-full bg-secondary-container text-on-secondary shadow-sm"
      >
        <Icon name="neurology" className="text-[18px]" />
      </div>
      <div className="flex max-w-[88%] flex-col gap-space-sm rounded-2xl rounded-tl-none bg-surface-container-lowest p-space-md shadow-sm">
        <div className="flex items-center gap-1.5">
          <span className="font-label-sm text-label-sm font-bold text-secondary">
            Trợ lý Socratic
          </span>
          <span className="font-label-sm text-label-sm text-on-surface-variant">
            • {message.time}
          </span>
        </div>
        <p className="break-words font-body-sm text-body-sm leading-relaxed text-on-surface">
          {message.text}
        </p>
        {message.quote ? (
          <blockquote className="break-words rounded-lg border-l-2 border-secondary bg-surface-container-low p-space-sm font-body-sm text-body-sm text-on-surface-variant">
            <Highlighted
              text={message.quote}
              highlight={message.highlight}
              highlightClass="font-semibold text-secondary"
            />
          </blockquote>
        ) : null}
        {message.suggestions && message.suggestions.length > 0 ? (
          <div className="flex flex-col gap-1.5 pt-1">
            <span className="font-label-sm text-label-sm text-on-surface-variant">
              Gợi ý tư duy nhanh cho bạn:
            </span>
            <div className="flex flex-wrap gap-1.5">
              {message.suggestions.map((suggestion, index) => (
                <button
                  key={suggestion}
                  type="button"
                  onClick={() => onSuggestion(suggestion)}
                  className={`rounded-full px-2.5 py-1 text-left font-label-sm text-label-sm transition-colors ${
                    index === 0
                      ? "bg-secondary-fixed text-on-secondary-fixed hover:bg-secondary hover:text-on-secondary"
                      : "bg-surface-container text-on-surface hover:bg-surface-container-high"
                  }`}
                >
                  {suggestion}
                </button>
              ))}
            </div>
          </div>
        ) : null}
      </div>
    </div>
  );
}
