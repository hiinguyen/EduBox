import type { ReactNode } from "react";
import { COMING_SOON_LABEL } from "@/lib/navigation";

interface DisabledNavItemProps {
  readonly label: string;
  readonly className: string;
  readonly children: ReactNode;
  readonly hasAriaLabel?: boolean;
}

// A link without href is not focusable, so assistive tech reads it as an unavailable link.
export function DisabledNavItem({
  label,
  className,
  children,
  hasAriaLabel = false,
}: DisabledNavItemProps) {
  return (
    <a
      role="link"
      aria-disabled="true"
      aria-label={hasAriaLabel ? `${label}, ${COMING_SOON_LABEL}` : undefined}
      title={COMING_SOON_LABEL}
      className={`${className} cursor-not-allowed opacity-60`}
    >
      {children}
    </a>
  );
}
