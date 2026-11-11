import { Icon } from "@/components/ui/icon";
import type { AiGradingSuggestion } from "@/lib/giao-vien/schemas";

interface AiSuggestionCardProps {
  readonly suggestion: AiGradingSuggestion;
  readonly onApply: (feedbackDraft: string) => void;
}

export function AiSuggestionCard({ suggestion, onApply }: AiSuggestionCardProps) {
  return (
    <div className="flex flex-col gap-space-xs rounded-lg bg-secondary-fixed/40 p-space-md">
      <div className="flex items-center gap-1.5 text-secondary">
        <Icon name="psychology" filled className="text-[18px]" />
        <span className="font-label-sm text-label-sm font-bold uppercase tracking-wide">
          Gợi ý nhận xét từ AI Trợ lý
        </span>
      </div>
      <p className="font-body-sm text-body-sm italic leading-relaxed text-on-surface">
        &quot;{suggestion.comment}&quot;
      </p>
      <button
        type="button"
        onClick={() => onApply(suggestion.feedbackDraft)}
        className="mt-1 flex items-center gap-0.5 self-start text-xs font-medium text-secondary hover:underline"
      >
        <Icon name="content_copy" className="text-[14px]" /> Áp dụng gợi ý này
      </button>
    </div>
  );
}
