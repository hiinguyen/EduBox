"use client";

import { useEffect, useId, useRef, useState, type FocusEvent } from "react";
import { SignOutButton } from "@/components/auth/sign-out-button";
import { Icon } from "@/components/ui/icon";
import type { CurrentUser } from "@/lib/current-user";

const SIGN_OUT_CLASS =
  "flex w-full items-center gap-space-sm rounded-lg px-space-md py-2.5 text-left font-label-md text-label-md text-error transition-colors hover:bg-error-container hover:text-on-error-container focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary";

interface UserMenuProps {
  readonly user: CurrentUser;
}

/** Account chip that discloses the user's identity and the sign-out control. */
export function UserMenu({ user }: UserMenuProps) {
  const [isOpen, setIsOpen] = useState(false);
  const rootRef = useRef<HTMLDivElement>(null);
  const toggleRef = useRef<HTMLButtonElement>(null);
  const panelId = useId();

  useEffect(() => {
    if (!isOpen) {
      return;
    }

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key !== "Escape") {
        return;
      }
      setIsOpen(false);
      toggleRef.current?.focus();
    };
    // Some browsers do not focus a button on click, so focus leave alone would miss outside clicks.
    const handlePointerDown = (event: PointerEvent) => {
      if (event.target instanceof Node && !rootRef.current?.contains(event.target)) {
        setIsOpen(false);
      }
    };

    document.addEventListener("keydown", handleKeyDown);
    document.addEventListener("pointerdown", handlePointerDown);
    return () => {
      document.removeEventListener("keydown", handleKeyDown);
      document.removeEventListener("pointerdown", handlePointerDown);
    };
  }, [isOpen]);

  const handleBlur = (event: FocusEvent<HTMLDivElement>) => {
    if (!event.currentTarget.contains(event.relatedTarget)) {
      setIsOpen(false);
    }
  };

  return (
    <div ref={rootRef} onBlur={handleBlur} className="relative">
      <button
        ref={toggleRef}
        type="button"
        aria-expanded={isOpen}
        aria-controls={panelId}
        aria-label={`Tài khoản của ${user.name}`}
        onClick={() => setIsOpen((open) => !open)}
        className="flex items-center gap-space-sm rounded-lg p-space-xs pl-space-xs transition-colors hover:bg-surface-container-high"
      >
        <span
          aria-hidden="true"
          className="grid h-8 w-8 place-items-center rounded-full bg-primary-fixed font-label-sm text-label-sm text-on-primary-fixed"
        >
          {user.initials}
        </span>
        <span className="hidden flex-col text-left lg:flex">
          <span className="font-label-md text-label-md leading-tight text-on-surface">
            {user.name}
          </span>
          <span className="font-label-sm text-label-sm leading-none text-on-surface-variant">
            {user.description}
          </span>
        </span>
        <Icon
          name={isOpen ? "expand_less" : "expand_more"}
          className="hidden text-[20px] text-on-surface-variant lg:inline"
        />
      </button>
      <div
        id={panelId}
        hidden={!isOpen}
        className="absolute right-0 top-full mt-space-sm w-64 rounded-xl border border-outline-variant/60 bg-surface-container-lowest p-space-sm shadow-level-3"
      >
        <div className="px-space-md py-space-sm">
          <p className="font-label-md text-label-md text-on-surface">{user.name}</p>
          <p className="font-label-sm text-label-sm text-on-surface-variant">{user.description}</p>
        </div>
        <SignOutButton className={SIGN_OUT_CLASS} />
      </div>
    </div>
  );
}
