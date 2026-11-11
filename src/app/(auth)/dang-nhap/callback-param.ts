import { sanitizeCallbackPath } from "@/lib/auth/route-access";

/** Reads the `callbackUrl` search param and keeps it only if it is a same-origin path. */
export function readCallbackParam(value: string | readonly string[] | undefined): string | null {
  const first = typeof value === "string" || value === undefined ? value : value[0];
  return sanitizeCallbackPath(first);
}
