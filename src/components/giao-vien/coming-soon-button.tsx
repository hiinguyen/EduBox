import type { ReactNode } from "react";
import { COMING_SOON_LABEL } from "@/lib/navigation";

interface ComingSoonButtonProps {
  readonly className: string;
  readonly children: ReactNode;
}

/** A control whose feature does not exist yet; it must not look or behave as live. */
export function ComingSoonButton({ className, children }: ComingSoonButtonProps) {
  return (
    <button
      type="button"
      disabled
      aria-disabled="true"
      title={COMING_SOON_LABEL}
      className={`${className} cursor-not-allowed opacity-60`}
    >
      {children}
    </button>
  );
}
