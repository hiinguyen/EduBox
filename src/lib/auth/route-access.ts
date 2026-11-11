import type { Role } from "@/generated/prisma/enums";
import { ROLE_HOME, SIGN_IN_PATH } from "./roles";

/** Which roles may open each protected screen. Keep in sync with src/lib/screens.ts. */
export const SCREEN_ROLES = {
  "/hoc-tap": ["STUDENT"],
  "/thi-truc-tuyen": ["STUDENT"],
  "/phu-huynh": ["PARENT"],
  "/giao-vien": ["TEACHER"],
} as const satisfies Record<string, readonly Role[]>;

export type RouteDecision =
  { readonly type: "allow" } | { readonly type: "login" } | { readonly type: "forbidden" };

function screenPrefixOf(pathname: string): keyof typeof SCREEN_ROLES | null {
  const prefixes = Object.keys(SCREEN_ROLES) as (keyof typeof SCREEN_ROLES)[];
  return (
    prefixes.find((prefix) => pathname === prefix || pathname.startsWith(`${prefix}/`)) ?? null
  );
}

/** Coarse gate used by the proxy. Pages and actions still enforce roles on the server. */
export function decideRouteAccess(pathname: string, role: Role | null): RouteDecision {
  const prefix = screenPrefixOf(pathname);

  if (prefix === null) {
    return { type: "allow" };
  }
  if (role === null) {
    return { type: "login" };
  }

  const allowed: readonly Role[] = SCREEN_ROLES[prefix];
  return allowed.includes(role) ? { type: "allow" } : { type: "forbidden" };
}

/** Accepts only same-origin absolute paths; everything else is dropped to prevent open redirects. */
export function sanitizeCallbackPath(candidate: string | null | undefined): string | null {
  if (!candidate || !candidate.startsWith("/") || candidate.startsWith("//")) {
    return null;
  }
  if (candidate.includes("\\") || /[\u0000-\u001f]/.test(candidate)) {
    return null;
  }
  return candidate;
}

export function resolvePostLoginPath(role: Role, callbackUrl: string | null | undefined): string {
  const callback = sanitizeCallbackPath(callbackUrl);
  const pathname = callback?.split(/[?#]/)[0] ?? "";

  if (callback && pathname !== "" && decideRouteAccess(pathname, role).type === "allow") {
    return callback;
  }
  return ROLE_HOME[role];
}

export function buildSignInUrl(callbackPath: string): string {
  const safe = sanitizeCallbackPath(callbackPath);
  return safe ? `${SIGN_IN_PATH}?callbackUrl=${encodeURIComponent(safe)}` : SIGN_IN_PATH;
}
