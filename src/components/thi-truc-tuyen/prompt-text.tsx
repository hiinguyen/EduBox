import type { PromptSegment } from "@/lib/thi-truc-tuyen/types";

const SEGMENT_CLASS: Readonly<Record<PromptSegment["kind"], string | undefined>> = {
  text: undefined,
  math: "font-serif italic font-bold",
  code: "font-mono",
};

interface PromptTextProps {
  readonly segments: readonly PromptSegment[];
}

export function PromptText({ segments }: PromptTextProps) {
  return (
    <>
      {segments.map((segment, index) => (
        <span key={`${index}-${segment.text}`} className={SEGMENT_CLASS[segment.kind]}>
          {segment.text}
        </span>
      ))}
    </>
  );
}
