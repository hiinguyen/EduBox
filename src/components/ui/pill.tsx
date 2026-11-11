import type { ReactNode } from "react";
import { TONE_BG_CLASS, type Tone } from "@/lib/ui/tone";

interface PillProps {
  readonly tone?: Tone;
  readonly className?: string;
  readonly children: ReactNode;
}

export function Pill({ tone = "neutral", className, children }: PillProps) {
  return (
    <span
      className={`inline-flex items-center gap-1 rounded-full px-2 py-0.5 font-label-sm text-label-sm ${TONE_BG_CLASS[tone]} ${className ?? ""}`}
    >
      {children}
    </span>
  );
}
