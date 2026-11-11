import "server-only";
import { getEnv } from "@/lib/env";
import { rateLimit } from "@/lib/rate-limit";
import { clientIpFromHeaders, hashKeyPart } from "./sign-in-keys";

const MS_PER_MINUTE = 60_000;
export const SIGN_IN_WINDOW_MS = 15 * MS_PER_MINUTE;
export const SIGN_IN_LIMIT_PER_EMAIL = 8;
export const SIGN_IN_LIMIT_PER_IP = 30;
/** Cap on all sign-in attempts per minute, checked before any argon2 work. */
export const SIGN_IN_GLOBAL_LIMIT_PER_MINUTE = 120;
export const SIGN_IN_GLOBAL_WINDOW_MS = MS_PER_MINUTE;
const GLOBAL_KEY = "signin:global";

/** True when this attempt must be refused. Order: global cap, per IP (if trusted), per email. */
export async function isSignInBlocked(request: Request, email: string | null): Promise<boolean> {
  const { AUTH_SECRET, TRUSTED_PROXY_HOPS } = getEnv();
  const window = { windowMs: SIGN_IN_WINDOW_MS };

  const global = await rateLimit(GLOBAL_KEY, {
    limit: SIGN_IN_GLOBAL_LIMIT_PER_MINUTE,
    windowMs: SIGN_IN_GLOBAL_WINDOW_MS,
  });
  if (!global.isAllowed) {
    return true;
  }

  const ip = clientIpFromHeaders(request.headers, TRUSTED_PROXY_HOPS);
  if (ip !== null) {
    const byIp = await rateLimit(`signin:ip:${hashKeyPart(AUTH_SECRET, ip)}`, {
      ...window,
      limit: SIGN_IN_LIMIT_PER_IP,
    });
    if (!byIp.isAllowed) {
      return true;
    }
  }

  if (email === null) {
    return false;
  }
  const byEmail = await rateLimit(`signin:email:${hashKeyPart(AUTH_SECRET, email)}`, {
    ...window,
    limit: SIGN_IN_LIMIT_PER_EMAIL,
  });
  return !byEmail.isAllowed;
}
