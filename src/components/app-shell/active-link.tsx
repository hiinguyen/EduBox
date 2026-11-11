"use client";

import Link from "next/link";
import { usePathname } from "next/navigation";
import type { ReactNode } from "react";
import { isActivePath } from "@/lib/navigation";

interface ActiveLinkProps {
  readonly href: string;
  readonly children: ReactNode;
  readonly className: string;
  readonly activeClassName?: string;
  readonly inactiveClassName?: string;
  readonly ariaLabel?: string;
  readonly title?: string;
  readonly onClick?: () => void;
}

export function ActiveLink({
  href,
  children,
  className,
  activeClassName = "",
  inactiveClassName = "",
  ariaLabel,
  title,
  onClick,
}: ActiveLinkProps) {
  const pathname = usePathname();
  const isActive = isActivePath(pathname, href);
  const stateClassName = isActive ? activeClassName : inactiveClassName;

  return (
    <Link
      href={href}
      aria-current={isActive ? "page" : undefined}
      aria-label={ariaLabel}
      title={title}
      onClick={onClick}
      className={`${className} ${stateClassName}`.trim()}
    >
      {children}
    </Link>
  );
}
