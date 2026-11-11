import Link from "next/link";
import type { Pagination } from "@/lib/giao-vien/pagination";

interface PaginationNavProps {
  readonly label: string;
  readonly pagination: Pagination;
  readonly hrefForPage: (page: number) => string;
}

const BUTTON_CLASS =
  "rounded-lg px-space-sm py-1 font-label-sm text-label-sm transition-colors focus-visible:outline-2 focus-visible:outline-primary";
const ACTIVE_CLASS = `${BUTTON_CLASS} bg-surface-container-high text-on-surface hover:bg-surface-container`;
const DISABLED_CLASS = `${BUTTON_CLASS} cursor-not-allowed bg-surface-container-low text-outline opacity-60`;

interface StepLinkProps {
  readonly isEnabled: boolean;
  readonly href: string;
  readonly rel: "prev" | "next";
  readonly children: string;
}

function StepLink({ isEnabled, href, rel, children }: StepLinkProps) {
  if (!isEnabled) {
    return (
      <span aria-disabled="true" className={DISABLED_CLASS}>
        {children}
      </span>
    );
  }
  return (
    <Link href={href} rel={rel} scroll={false} className={ACTIVE_CLASS}>
      {children}
    </Link>
  );
}

export function PaginationNav({ label, pagination, hrefForPage }: PaginationNavProps) {
  const { page, totalPages, totalItems, from, to, hasPrevious, hasNext } = pagination;
  if (totalItems === 0) return null;

  return (
    <nav
      aria-label={label}
      className="flex flex-wrap items-center justify-between gap-space-sm font-body-sm text-body-sm text-on-surface-variant"
    >
      <span>
        Hiển thị {from}-{to} / {totalItems}
      </span>
      <div className="flex items-center gap-space-xs">
        <StepLink isEnabled={hasPrevious} href={hrefForPage(page - 1)} rel="prev">
          Trang trước
        </StepLink>
        <span className="px-space-xs font-semibold text-on-surface">
          Trang {page} / {totalPages}
        </span>
        <StepLink isEnabled={hasNext} href={hrefForPage(page + 1)} rel="next">
          Trang sau
        </StepLink>
      </div>
    </nav>
  );
}
