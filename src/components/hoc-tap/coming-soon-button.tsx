import type { ReactNode } from "react";
import { COMING_SOON_LABEL } from "@/lib/navigation";

interface ComingSoonButtonProps {
  readonly className?: string;
  readonly label?: string;
  readonly children: ReactNode;
}

/** A control whose feature is not built yet; it stays visible but is clearly unavailable. */
export function ComingSoonButton({ className, label, children }: ComingSoonButtonProps) {
  return (
    <button
      type="button"
      disabled
      aria-disabled="true"
      aria-label={label ? `${label}, ${COMING_SOON_LABEL}` : undefined}
      title={COMING_SOON_LABEL}
      className={`${className ?? ""} cursor-not-allowed opacity-60`}
    >
      {children}
    </button>
  );
}
