"use client";

import Link from "next/link";
import { useId, useRef, useState } from "react";
import type { FocusEvent, KeyboardEvent } from "react";
import { Avatar } from "@/components/ui/avatar";
import { Icon } from "@/components/ui/icon";
import type { ChildOption } from "@/lib/phu-huynh/view-model";

interface ChildSwitcherProps {
  readonly childOptions: readonly ChildOption[];
  readonly selectedChildId: string;
}

function ChildSummary({ child }: { readonly child: ChildOption }) {
  return (
    <>
      <Avatar name={child.name} />
      <span className="flex flex-col text-left">
        <span className="flex items-center gap-1.5">
          <span className="font-label-md text-label-md font-semibold text-on-surface">
            {child.name}
          </span>
          <span className="rounded bg-primary-fixed px-1.5 py-0.5 font-label-sm text-label-sm text-on-primary-fixed">
            {child.className}
          </span>
        </span>
        <span className="font-body-sm text-body-sm text-on-surface-variant">
          Mã HS: {child.studentCode}
        </span>
      </span>
    </>
  );
}

export function ChildSwitcher({ childOptions, selectedChildId }: ChildSwitcherProps) {
  const [isOpen, setIsOpen] = useState(false);
  const containerRef = useRef<HTMLDivElement>(null);
  const triggerRef = useRef<HTMLButtonElement>(null);
  const listId = useId();
  const selected = childOptions.find((child) => child.id === selectedChildId);

  if (!selected) return null;

  const handleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    if (event.key !== "Escape" || !isOpen) return;
    setIsOpen(false);
    triggerRef.current?.focus();
  };

  const handleBlur = (event: FocusEvent<HTMLDivElement>) => {
    const next = event.relatedTarget;
    if (next instanceof Node && containerRef.current?.contains(next)) return;
    setIsOpen(false);
  };

  return (
    <div
      ref={containerRef}
      onKeyDown={handleKeyDown}
      onBlur={handleBlur}
      className="relative w-full shrink-0 md:w-auto"
    >
      <button
        ref={triggerRef}
        type="button"
        aria-expanded={isOpen}
        aria-controls={listId}
        aria-label={`Chuyển hồ sơ học sinh, đang xem ${selected.name}`}
        onClick={() => setIsOpen((open) => !open)}
        className="flex w-full items-center justify-between gap-space-md rounded-xl bg-surface-container-low p-2.5 text-left shadow-sm transition-all hover:bg-surface-container focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary md:w-auto"
      >
        <span className="flex items-center gap-space-sm">
          <ChildSummary child={selected} />
        </span>
        <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-surface-container-lowest text-on-surface-variant">
          <Icon name="unfold_more" className="text-[20px]" />
        </span>
      </button>
      {isOpen ? (
        <ul
          id={listId}
          className="absolute right-0 top-full z-20 mt-2 flex w-full min-w-72 flex-col gap-1 rounded-xl bg-surface-container-lowest p-1 shadow-level-2 ring-1 ring-outline-variant/40"
        >
          {childOptions.map((child) => (
            <li key={child.id}>
              <Link
                href={`?con=${child.id}`}
                aria-current={child.id === selectedChildId ? "true" : undefined}
                onClick={() => setIsOpen(false)}
                className="flex items-center gap-space-sm rounded-lg p-2.5 hover:bg-surface-container-low focus-visible:outline-2 focus-visible:outline-primary aria-[current=true]:bg-surface-container-low"
              >
                <ChildSummary child={child} />
              </Link>
            </li>
          ))}
        </ul>
      ) : null}
    </div>
  );
}
