import { SCREEN_ROLES } from "./auth/route-access";
import type { UserRole } from "./current-user";
import { getScreen, type ScreenHref } from "./screens";

export interface NavItem {
  readonly href: ScreenHref;
  readonly label: string;
  readonly icon: string;
  readonly shortLabel: string;
}

export interface SystemNavItem {
  readonly id: string;
  readonly label: string;
  readonly icon: string;
}

export interface RoleSwitchItem {
  readonly href: ScreenHref;
  readonly label: string;
}

// Sidebar order from design/hoc-tap/code.html, labels come from the screen catalogue.
const PRIMARY_NAV_ORDER = [
  "/hoc-tap",
  "/thi-truc-tuyen",
  "/giao-vien",
  "/phu-huynh",
] as const satisfies readonly ScreenHref[];

const PRIMARY_NAV_META = {
  "/hoc-tap": { icon: "auto_stories", shortLabel: "Học tập" },
  "/thi-truc-tuyen": { icon: "timer", shortLabel: "Làm bài" },
  "/giao-vien": { icon: "co_present", shortLabel: "Giáo viên" },
  "/phu-huynh": { icon: "supervised_user_circle", shortLabel: "Phụ huynh" },
} as const satisfies Record<ScreenHref, { icon: string; shortLabel: string }>;

export const PRIMARY_NAV: readonly NavItem[] = PRIMARY_NAV_ORDER.map((href) => ({
  href,
  label: getScreen(href).title,
  icon: PRIMARY_NAV_META[href].icon,
  shortLabel: PRIMARY_NAV_META[href].shortLabel,
}));

/** Areas the role may open, from the same map the proxy uses so the two cannot diverge. */
export function getPrimaryNavForRole(role: UserRole): readonly NavItem[] {
  return PRIMARY_NAV.filter((item) => {
    const allowed: readonly UserRole[] = SCREEN_ROLES[item.href];
    return allowed.includes(role);
  });
}

// No routes exist for these yet, so they carry an id instead of an href and render disabled.
export const SYSTEM_NAV = [
  { id: "tai-lieu-thu-vien", label: "Tài liệu thư viện", icon: "menu_book" },
  { id: "cai-dat-tai-khoan", label: "Cài đặt tài khoản", icon: "settings" },
  { id: "ho-tro-24-7", label: "Hỗ trợ 24/7", icon: "support_agent" },
] as const satisfies readonly SystemNavItem[];

export const COMING_SOON_LABEL = "Sắp ra mắt";

export const ROLE_SWITCHER = [
  { href: "/hoc-tap", label: "Học sinh" },
  { href: "/giao-vien", label: "Giáo viên" },
  { href: "/phu-huynh", label: "Phụ huynh" },
] as const satisfies readonly RoleSwitchItem[];

// Each switch target belongs to exactly one role; a user only ever sees their own.
const ROLE_SWITCH_OWNER = {
  "/hoc-tap": "STUDENT",
  "/giao-vien": "TEACHER",
  "/phu-huynh": "PARENT",
} as const satisfies Partial<Record<ScreenHref, UserRole>>;

export function getRoleSwitchItems(role: UserRole): readonly RoleSwitchItem[] {
  return ROLE_SWITCHER.filter((item) => ROLE_SWITCH_OWNER[item.href] === role);
}

const ROOT_PATH = "/";

function normalizePath(path: string): string {
  if (path.length <= ROOT_PATH.length) {
    return path;
  }

  return path.replace(/\/+$/, "");
}

export function isActivePath(pathname: string, href: string): boolean {
  const current = normalizePath(pathname);
  const target = normalizePath(href);

  return current === target || current.startsWith(`${target}/`);
}
