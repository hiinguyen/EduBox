"use client";

import { getRoleSwitchItems } from "@/lib/navigation";
import { ActiveLink } from "./active-link";
import { useRole } from "./role-context";

interface RoleSwitcherProps {
  readonly className?: string;
  readonly onNavigate?: () => void;
}

const ROLE_LINK_CLASS =
  "rounded-full px-space-md py-1.5 font-label-sm text-label-sm transition-colors";
const ROLE_ACTIVE_CLASS =
  "bg-surface-container-lowest text-primary shadow-[0_1px_2px_rgba(15,23,42,0.05)]";
const ROLE_INACTIVE_CLASS = "text-on-surface-variant hover:text-on-surface";

export function RoleSwitcher({ className, onNavigate }: RoleSwitcherProps) {
  const role = useRole();
  const items = role ? getRoleSwitchItems(role) : [];

  if (items.length === 0) {
    return null;
  }

  const [onlyItem] = items;

  if (items.length === 1 && onlyItem) {
    // One role has nothing to switch to, so it is a plain label rather than a link.
    return (
      <span
        className={`w-fit items-center rounded-full bg-surface-container-high px-space-md py-space-xs font-label-sm text-label-sm text-primary ${
          className ?? "flex"
        }`}
      >
        <span className="sr-only">Vai trò: </span>
        {onlyItem.label}
      </span>
    );
  }

  return (
    <nav
      aria-label="Chuyển vai trò"
      className={`items-center rounded-full bg-surface-container-high p-space-xs shadow-[0_1px_3px_rgba(15,23,42,0.05)] ${
        className ?? "flex"
      }`}
    >
      {items.map((item) => (
        <ActiveLink
          key={item.href}
          href={item.href}
          onClick={onNavigate}
          className={ROLE_LINK_CLASS}
          activeClassName={ROLE_ACTIVE_CLASS}
          inactiveClassName={ROLE_INACTIVE_CLASS}
        >
          {item.label}
        </ActiveLink>
      ))}
    </nav>
  );
}
