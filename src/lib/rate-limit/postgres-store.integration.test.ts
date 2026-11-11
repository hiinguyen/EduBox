import { afterAll, beforeEach, describe, expect, it } from "vitest";
import { db } from "@/lib/db";
import { PURGE_RETENTION_MS, createRateLimiter } from "./fixed-window";
import { postgresStore } from "./postgres-store";

const WINDOW_MS = 60_000;
const START = new Date("2026-01-01T00:00:00.000Z");
const BURST_SIZE = 12;
const BURST_LIMIT = 5;

function limiterAt(offsetMs: number) {
  return createRateLimiter(postgresStore, { clock: () => new Date(START.getTime() + offsetMs) });
}

// Runs against the dedicated <db>_test database, so clearing the table is safe here.
beforeEach(async () => {
  await db.rateLimitBucket.deleteMany();
});

afterAll(async () => {
  await db.rateLimitBucket.deleteMany();
  await db.$disconnect();
});

describe("postgres rate limit store", () => {
  it("blocks after the limit within one window", async () => {
    const options = { limit: 2, windowMs: WINDOW_MS };
    const limiter = limiterAt(0);

    const results = [
      await limiter("k", options),
      await limiter("k", options),
      await limiter("k", options),
    ];

    expect(results.map((result) => result.isAllowed)).toEqual([true, true, false]);
  });

  it("starts a fresh window after windowMs has elapsed", async () => {
    const options = { limit: 1, windowMs: WINDOW_MS };

    await limiterAt(0)("k", options);
    const blocked = await limiterAt(1_000)("k", options);
    const fresh = await limiterAt(WINDOW_MS + 1)("k", options);

    expect(blocked.isAllowed).toBe(false);
    expect(fresh.isAllowed).toBe(true);
  });

  it("counts concurrent hits atomically", async () => {
    const options = { limit: BURST_LIMIT, windowMs: WINDOW_MS };
    const limiter = limiterAt(0);

    const results = await Promise.all(
      Array.from({ length: BURST_SIZE }, () => limiter("burst", options)),
    );

    expect(results.filter((result) => result.isAllowed)).toHaveLength(BURST_LIMIT);
  });

  it("keeps keys independent", async () => {
    const options = { limit: 1, windowMs: WINDOW_MS };
    const limiter = limiterAt(0);

    await limiter("a", options);

    expect((await limiter("b", options)).isAllowed).toBe(true);
  });

  it("purges buckets past the retention and keeps recent ones", async () => {
    const options = { limit: 5, windowMs: WINDOW_MS };
    await limiterAt(0)("stale", options);
    await limiterAt(PURGE_RETENTION_MS)("recent", options);
    const purging = createRateLimiter(postgresStore, {
      clock: () => new Date(START.getTime() + PURGE_RETENTION_MS + WINDOW_MS),
      random: () => 0,
    });

    await purging("trigger", options);

    const keys = (await db.rateLimitBucket.findMany({ select: { key: true } })).map((r) => r.key);
    expect(keys.sort()).toEqual(["recent", "trigger"]);
  });
});
