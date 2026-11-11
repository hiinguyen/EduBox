"use client";

import { useEffect, useRef, useState } from "react";
import { usePathname } from "next/navigation";
import { Icon } from "@/components/ui/icon";
import { SignOutButton } from "@/components/auth/sign-out-button";
import type { UserRole } from "@/lib/current-user";
import { getPrimaryNavForRole, SYSTEM_NAV } from "@/lib/navigation";
import { ActiveLink } from "./active-link";
import { DisabledNavItem } from "./disabled-nav-item";
import { RoleSwitcher } from "./role-switcher";

const MENU_ID = "mobile-navigation-menu";
const TAB_LINK_CLASS =
  "flex min-w-0 flex-col items-center justify-center gap-1 rounded-lg px-1 font-label-sm text-label-sm transition-colors";
const TAB_ACTIVE_CLASS = "text-primary";
const TAB_INACTIVE_CLASS = "text-on-surface-variant hover:text-on-surface";
const MENU_LABEL_CLASS = "font-label-sm text-label-sm uppercase tracking-wider text-outline";
const MENU_ITEM_CLASS =
  "flex items-center gap-space-md rounded-lg px-space-md py-2.5 font-label-md text-label-md text-on-surface-variant";
const SIGN_OUT_CLASS =
  "flex w-full items-center gap-space-md rounded-lg px-space-md py-2.5 font-label-md text-label-md text-error transition-colors hover:bg-error-container hover:text-on-error-container";

interface MobileNavigationProps {
  readonly role: UserRole;
}

export function MobileNavigation({ role }: MobileNavigationProps) {
  const primaryNav = getPrimaryNavForRole(role);
  const tabCount = primaryNav.length + 1;
  const pathname = usePathname();
  const [isMenuOpen, setIsMenuOpen] = useState(false);
  const [menuPathname, setMenuPathname] = useState(pathname);
  const toggleRef = useRef<HTMLButtonElement>(null);
  const closeMenu = () => setIsMenuOpen(false);

  // Close on navigation by comparing during render instead of setting state in an effect.
  if (menuPathname !== pathname) {
    setMenuPathname(pathname);
    setIsMenuOpen(false);
  }

  useEffect(() => {
    if (!isMenuOpen) {
      return;
    }

    const handleKeyDown = (event: KeyboardEvent) => {
      if (event.key !== "Escape") {
        return;
      }
      setIsMenuOpen(false);
      toggleRef.current?.focus();
    };

    document.addEventListener("keydown", handleKeyDown);
    return () => document.removeEventListener("keydown", handleKeyDown);
  }, [isMenuOpen]);

  return (
    <>
      <nav
        aria-label="Điều hướng chính"
        className="fixed inset-x-0 bottom-0 z-50 border-t border-outline-variant/40 bg-surface-container-lowest/95 pb-[env(safe-area-inset-bottom)] backdrop-blur-xl md:hidden"
      >
        <div
          className="grid h-16 items-stretch px-space-xs"
          style={{ gridTemplateColumns: `repeat(${tabCount}, minmax(0, 1fr))` }}
        >
          {primaryNav.map((item) => (
            <ActiveLink
              key={item.href}
              href={item.href}
              ariaLabel={item.label}
              onClick={closeMenu}
              className={TAB_LINK_CLASS}
              activeClassName={TAB_ACTIVE_CLASS}
              inactiveClassName={TAB_INACTIVE_CLASS}
            >
              <Icon name={item.icon} className="text-[22px]" />
              <span className="w-full truncate text-center">{item.shortLabel}</span>
            </ActiveLink>
          ))}
          <button
            ref={toggleRef}
            type="button"
            aria-expanded={isMenuOpen}
            aria-controls={MENU_ID}
            aria-label={isMenuOpen ? "Đóng menu" : "Mở menu"}
            onClick={() => setIsMenuOpen((open) => !open)}
            className={TAB_LINK_CLASS}
          >
            <Icon name={isMenuOpen ? "close" : "more_horiz"} className="text-[22px]" />
            <span className="w-full truncate text-center">{isMenuOpen ? "Đóng" : "Thêm"}</span>
          </button>
        </div>
      </nav>

      {/* Placed right after the nav so Tab from the toggle reaches the menu. */}
      {isMenuOpen ? (
        <button
          type="button"
          tabIndex={-1}
          aria-hidden="true"
          onClick={closeMenu}
          className="fixed inset-0 z-40 bg-inverse-surface/40 backdrop-blur-sm md:hidden"
        />
      ) : null}
      <div
        id={MENU_ID}
        hidden={!isMenuOpen}
        className="fixed inset-x-0 bottom-[calc(5rem+env(safe-area-inset-bottom))] z-50 mx-space-md rounded-xl border border-outline-variant/60 bg-surface-container-lowest p-space-md shadow-level-3 md:hidden"
      >
        <p className={MENU_LABEL_CLASS}>Hệ thống &amp; Hỗ trợ</p>
        <nav aria-label="Hệ thống và hỗ trợ" className="mt-space-xs flex flex-col gap-1">
          {SYSTEM_NAV.map((item) => (
            <DisabledNavItem key={item.id} label={item.label} className={MENU_ITEM_CLASS}>
              <Icon name={item.icon} className="text-[20px]" />
              <span>{item.label}</span>
            </DisabledNavItem>
          ))}
        </nav>
        <p className={`mt-space-md ${MENU_LABEL_CLASS}`}>Chuyển vai trò</p>
        <RoleSwitcher className="mt-space-sm flex" onNavigate={closeMenu} />
        <div className="mt-space-md border-t border-outline-variant/40 pt-space-sm">
          <SignOutButton className={SIGN_OUT_CLASS} />
        </div>
      </div>
    </>
  );
}
