import { createHmac } from "node:crypto";

const UNKNOWN_IP = "unknown";

/** HMAC-SHA256 hex of a client-controlled value: fixed length, and the raw value never reaches the table. */
export function hashKeyPart(secret: string, value: string): string {
  return createHmac("sha256", secret).update(value).digest("hex");
}

/**
 * The client address as seen by the trusted proxy chain. `x-forwarded-for` is only
 * trustworthy for the entries our own proxies appended, so with `trustedHops` = N we take
 * the N-th entry from the right. With 0 hops every forwarding header is attacker-controlled
 * and ignored.
 */
export function clientIpFromHeaders(headers: Headers, trustedHops: number): string | null {
  if (trustedHops <= 0) {
    return null;
  }
  const entries = (headers.get("x-forwarded-for") ?? "")
    .split(",")
    .map((entry) => entry.trim())
    .filter(Boolean);
  return entries[entries.length - trustedHops] ?? UNKNOWN_IP;
}
