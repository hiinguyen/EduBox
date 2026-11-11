import { ringDashOffset } from "@/lib/hoc-tap/timeline";

const RING_RADIUS = 26;
const RING_CIRCUMFERENCE = 2 * Math.PI * RING_RADIUS;

interface ProgressRingProps {
  readonly percent: number;
}

export function ProgressRing({ percent }: ProgressRingProps) {
  return (
    <div
      role="img"
      aria-label={`Tiến độ tuần ${percent}%`}
      className="relative flex h-16 w-16 flex-shrink-0 items-center justify-center"
    >
      <svg aria-hidden="true" className="h-16 w-16 -rotate-90" viewBox="0 0 64 64">
        <circle
          className="text-surface-container"
          cx="32"
          cy="32"
          fill="transparent"
          r={RING_RADIUS}
          stroke="currentColor"
          strokeWidth="6"
        />
        <circle
          className="text-primary-container"
          cx="32"
          cy="32"
          fill="transparent"
          r={RING_RADIUS}
          stroke="currentColor"
          strokeDasharray={RING_CIRCUMFERENCE}
          strokeDashoffset={ringDashOffset(percent, RING_CIRCUMFERENCE)}
          strokeLinecap="round"
          strokeWidth="6"
        />
      </svg>
      <span className="absolute font-headline-sm text-headline-sm font-bold text-primary">
        {percent}%
      </span>
    </div>
  );
}
