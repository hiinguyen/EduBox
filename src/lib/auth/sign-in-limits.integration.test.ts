import { randomBytes } from "node:crypto";
import { afterAll, describe, expect, it } from "vitest";
import { db } from "@/lib/db";
import {
  SIGN_IN_GLOBAL_LIMIT_PER_MINUTE,
  SIGN_IN_LIMIT_PER_EMAIL,
  isSignInBlocked,
} from "./sign-in-limits";

const GLOBAL_KEY = "signin:global";
const request = (forwardedFor: string) =>
  new Request("http://localhost/api/auth/callback/credentials", {
    method: "POST",
    headers: { "x-forwarded-for": forwardedFor },
  });

afterAll(async () => {
  await db.rateLimitBucket.deleteMany({ where: { key: { startsWith: "signin:" } } });
  await db.$disconnect();
});

describe("isSignInBlocked", () => {
  it("blocks the email after its limit even when X-Forwarded-For rotates", async () => {
    const email = `flood-${randomBytes(4).toString("hex")}@test.local`;
    const results: boolean[] = [];

    for (let attempt = 0; attempt <= SIGN_IN_LIMIT_PER_EMAIL; attempt += 1) {
      results.push(await isSignInBlocked(request(`10.0.0.${attempt}`), email));
    }

    expect(results.slice(0, SIGN_IN_LIMIT_PER_EMAIL).every((blocked) => !blocked)).toBe(true);
    expect(results[SIGN_IN_LIMIT_PER_EMAIL]).toBe(true);
  });

  it("stores only a hash of the email, never the raw address", async () => {
    const email = `hashed-${randomBytes(4).toString("hex")}@test.local`;

    await isSignInBlocked(request("1.1.1.1"), email);

    const keys = (await db.rateLimitBucket.findMany({ select: { key: true } })).map((r) => r.key);
    expect(keys.some((key) => key.includes(email))).toBe(false);
    expect(keys.some((key) => /^signin:email:[0-9a-f]{64}$/.test(key))).toBe(true);
  });

  it("blocks everything once the global cap is used up, before any per-email check", async () => {
    await db.rateLimitBucket.upsert({
      where: { key: GLOBAL_KEY },
      create: { key: GLOBAL_KEY, count: SIGN_IN_GLOBAL_LIMIT_PER_MINUTE, windowStart: new Date() },
      update: { count: SIGN_IN_GLOBAL_LIMIT_PER_MINUTE, windowStart: new Date() },
    });

    const blocked = await isSignInBlocked(request("9.9.9.9"), null);

    expect(blocked).toBe(true);
  });
});
