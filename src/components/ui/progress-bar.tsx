import { clampPercent } from "@/lib/format/percent";
import { TONE_BAR_CLASS, type Tone } from "@/lib/ui/tone";

interface ProgressBarProps {
  readonly value: number;
  readonly label: string;
  readonly tone?: Tone;
  readonly className?: string;
}

export function ProgressBar({ value, label, tone = "primary", className }: ProgressBarProps) {
  const percent = clampPercent(value);
  return (
    <div
      role="progressbar"
      aria-label={label}
      aria-valuemin={0}
      aria-valuemax={100}
      aria-valuenow={Math.round(percent)}
      className={`h-2 w-full overflow-hidden rounded-full bg-surface-container-high ${className ?? ""}`}
    >
      <div
        className={`h-full rounded-full ${TONE_BAR_CLASS[tone]}`}
        style={{ width: `${percent}%` }}
      />
    </div>
  );
}
