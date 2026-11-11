import Link from "next/link";
import { Icon } from "@/components/ui/icon";
import { ROLE_HOME } from "@/lib/auth/roles";
import type { CurrentUser } from "@/lib/current-user";
import { COMING_SOON_LABEL } from "@/lib/navigation";
import { RoleSwitcher } from "./role-switcher";
import { UserMenu } from "./user-menu";

const SEARCH_LABEL = "Tìm kiếm khóa học, tài liệu, bài giảng";
const TOP_BAR_SHADOW = "shadow-[0_1px_8px_rgba(0,0,0,0.04)]";
const SOFT_SHADOW = "shadow-[0_1px_3px_rgba(15,23,42,0.05)]";
const AI_CHIP_SHADOW = "shadow-[0_1px_2px_rgba(15,23,42,0.05)]";
// Placeholder until notifications are backed by data.
const HAS_UNREAD_NOTIFICATIONS = true;
const NOTIFICATIONS_LABEL = "Thông báo";
const NOTIFICATIONS_UNREAD_LABEL = `${NOTIFICATIONS_LABEL}, có thông báo chưa đọc`;

interface TopBarProps {
  readonly user: CurrentUser;
}

export function TopBar({ user }: TopBarProps) {
  return (
    <header
      className={`fixed inset-x-0 top-0 z-50 h-16 bg-surface/85 backdrop-blur-xl ${TOP_BAR_SHADOW}`}
    >
      <div className="flex h-16 w-full items-center justify-between gap-space-md px-gutter-mobile md:px-gutter">
        <div className="flex items-center gap-space-lg">
          <Link
            href={ROLE_HOME[user.role]}
            aria-label="EduSmart, về trang chủ"
            className="flex items-center gap-space-sm rounded-lg"
          >
            <span className="grid h-8 w-8 place-items-center rounded-lg bg-primary-container text-on-primary">
              <Icon name="auto_stories" filled className="text-[20px]" />
            </span>
            <span className="font-headline-sm text-headline-sm tracking-tight text-primary">
              EduSmart
            </span>
          </Link>
          <RoleSwitcher className="hidden xl:flex" />
        </div>

        <div className="mx-space-md hidden max-w-xl flex-1 md:block">
          <div role="search" className="relative flex w-full items-center">
            <Icon
              name="search"
              className="pointer-events-none absolute left-space-md text-[20px] text-outline"
            />
            <label htmlFor="global-search" className="sr-only">
              {SEARCH_LABEL}
            </label>
            <input
              id="global-search"
              disabled
              title={COMING_SOON_LABEL}
              type="search"
              placeholder={`${SEARCH_LABEL}...`}
              className={`h-11 w-full rounded-lg border-0 bg-surface-container-lowest pl-11 pr-space-md font-body-sm text-body-sm text-on-surface placeholder:text-outline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary disabled:cursor-not-allowed ${SOFT_SHADOW}`}
            />
          </div>
        </div>

        <div className="flex items-center gap-space-md">
          {user.role === "STUDENT" ? (
            <Link
              href="/hoc-tap"
              aria-label="Mở trợ lý AI Socratic"
              className={`hidden items-center gap-space-xs rounded-full bg-secondary-fixed px-space-md py-1.5 font-label-sm text-label-sm text-on-secondary-fixed sm:flex ${AI_CHIP_SHADOW}`}
            >
              <Icon name="psychology" className="text-[18px] text-secondary" />
              <span>Trợ lý AI Socratic</span>
            </Link>
          ) : null}

          <button
            type="button"
            aria-label={HAS_UNREAD_NOTIFICATIONS ? NOTIFICATIONS_UNREAD_LABEL : NOTIFICATIONS_LABEL}
            className="relative rounded-lg p-2 text-on-surface-variant transition-colors hover:bg-surface-container-high hover:text-on-surface"
          >
            <Icon name="notifications" className="text-[22px]" />
            {HAS_UNREAD_NOTIFICATIONS ? (
              <span
                aria-hidden="true"
                className="absolute right-1.5 top-1.5 h-2 w-2 rounded-full bg-error"
              />
            ) : null}
          </button>

          <UserMenu user={user} />
        </div>
      </div>
    </header>
  );
}
