import { Icon } from "@/components/ui/icon";
import type { UserRole } from "@/lib/current-user";
import { getPrimaryNavForRole, SYSTEM_NAV } from "@/lib/navigation";
import { ActiveLink } from "./active-link";
import { DisabledNavItem } from "./disabled-nav-item";

const SIDEBAR_SHADOW = "shadow-[0_1px_8px_rgba(0,0,0,0.04)]";
const SECTION_LABEL_CLASS = "font-label-sm text-label-sm uppercase tracking-wider text-outline";
const PRIMARY_LINK_CLASS =
  "flex items-center justify-center gap-space-md rounded-lg px-space-sm py-3 font-label-md text-label-md transition-all lg:justify-start lg:px-space-md";
const PRIMARY_ACTIVE_CLASS = "bg-primary-container text-on-primary";
const PRIMARY_INACTIVE_CLASS =
  "text-on-surface-variant hover:bg-surface-container-high hover:text-on-surface";
const SYSTEM_LINK_CLASS =
  "flex items-center justify-center gap-space-md rounded-lg px-space-sm py-2.5 font-label-md text-label-md transition-all lg:justify-start lg:px-space-md";
const SYSTEM_TEXT_CLASS = "text-on-surface-variant";

interface SidebarProps {
  readonly role: UserRole;
}

export function Sidebar({ role }: SidebarProps) {
  return (
    <aside
      className={`fixed bottom-0 left-0 top-16 z-40 hidden w-20 flex-col justify-between bg-surface-container-lowest p-space-md md:flex lg:w-72 ${SIDEBAR_SHADOW}`}
    >
      <div className="flex flex-col gap-space-xs">
        <div className="hidden px-space-md py-space-xs lg:block">
          <span className={SECTION_LABEL_CLASS}>Khu vực học tập</span>
        </div>
        <nav aria-label="Khu vực học tập" className="flex flex-col gap-1">
          {getPrimaryNavForRole(role).map((item) => (
            <ActiveLink
              key={item.href}
              href={item.href}
              ariaLabel={item.label}
              title={item.label}
              className={PRIMARY_LINK_CLASS}
              activeClassName={PRIMARY_ACTIVE_CLASS}
              inactiveClassName={PRIMARY_INACTIVE_CLASS}
            >
              <Icon name={item.icon} className="text-[22px]" />
              <span className="hidden lg:inline">{item.label}</span>
            </ActiveLink>
          ))}
        </nav>
      </div>

      <div className="flex flex-col gap-space-xs">
        <div className="hidden px-space-md py-space-xs lg:block">
          <span className={SECTION_LABEL_CLASS}>Hệ thống &amp; Hỗ trợ</span>
        </div>
        <nav aria-label="Hệ thống và hỗ trợ" className="flex flex-col gap-1">
          {SYSTEM_NAV.map((item) => (
            <DisabledNavItem
              key={item.id}
              label={item.label}
              hasAriaLabel
              className={`${SYSTEM_LINK_CLASS} ${SYSTEM_TEXT_CLASS}`}
            >
              <Icon name={item.icon} className="text-[20px]" />
              <span className="hidden lg:inline">{item.label}</span>
            </DisabledNavItem>
          ))}
        </nav>
      </div>
    </aside>
  );
}
