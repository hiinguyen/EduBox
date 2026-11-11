interface SkeletonProps {
  readonly className?: string;
}

/** Decorative placeholder; pair it with a labelled live region on the loading screen. */
export function Skeleton({ className }: SkeletonProps) {
  return (
    <div
      aria-hidden="true"
      className={`animate-pulse rounded-lg bg-surface-container-high motion-reduce:animate-none ${className ?? ""}`}
    />
  );
}
