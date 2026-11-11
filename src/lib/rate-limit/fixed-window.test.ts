import { describe, expect, it, vi } from "vitest";
import {
  PURGE_PROBABILITY,
  PURGE_RETENTION_MS,
  createRateLimiter,
  evaluateWindow,
} from "./fixed-window";
import { createMemoryStore } from "./memory-store";

const WINDOW_MS = 60_000;
const START = new Date("2026-01-01T00:00:00.000Z");

function clockAt(offsetMs: number) {
  return () => new Date(START.getTime() + offsetMs);
}

describe("evaluateWindow", () => {
  it("allows a hit that lands exactly on the limit", () => {
    const result = evaluateWindow(
      { count: 3, windowStart: START },
      { limit: 3, windowMs: WINDOW_MS },
      START,
    );

    expect(result).toEqual({ isAllowed: true, remaining: 0, retryAfterMs: WINDOW_MS });
  });

  it("rejects a hit above the limit and reports time until the window ends", () => {
    const now = new Date(START.getTime() + 20_000);
    const result = evaluateWindow(
      { count: 4, windowStart: START },
      { limit: 3, windowMs: WINDOW_MS },
      now,
    );

    expect(result.isAllowed).toBe(false);
    expect(result.retryAfterMs).toBe(40_000);
  });
});

describe("createRateLimiter with the memory store", () => {
  it("blocks the request after the limit is used up", async () => {
    const rateLimit = createRateLimiter(createMemoryStore(), { clock: clockAt(0) });
    const options = { limit: 2, windowMs: WINDOW_MS };

    const results = [
      await rateLimit("k", options),
      await rateLimit("k", options),
      await rateLimit("k", options),
    ];

    expect(results.map((result) => result.isAllowed)).toEqual([true, true, false]);
  });

  it("keeps separate counters per key", async () => {
    const rateLimit = createRateLimiter(createMemoryStore(), { clock: clockAt(0) });
    const options = { limit: 1, windowMs: WINDOW_MS };

    await rateLimit("a", options);

    expect((await rateLimit("b", options)).isAllowed).toBe(true);
  });

  it("starts a new window once the previous one has elapsed", async () => {
    const store = createMemoryStore();
    const options = { limit: 1, windowMs: WINDOW_MS };

    await createRateLimiter(store, { clock: clockAt(0) })("k", options);
    const blocked = await createRateLimiter(store, { clock: clockAt(1_000) })("k", options);
    const afterWindow = await createRateLimiter(store, { clock: clockAt(WINDOW_MS + 1) })(
      "k",
      options,
    );

    expect(blocked.isAllowed).toBe(false);
    expect(afterWindow.isAllowed).toBe(true);
  });
});

describe("opportunistic purge", () => {
  const options = { limit: 5, windowMs: WINDOW_MS };

  it("removes buckets older than the retention when the dice roll hits", async () => {
    const store = createMemoryStore();
    await createRateLimiter(store, { clock: clockAt(0) })("old", options);
    const later = PURGE_RETENTION_MS + WINDOW_MS;
    const purgeSpy = vi.spyOn(store, "purgeExpired");

    await createRateLimiter(store, { clock: clockAt(later), random: () => 0 })("new", options);
    // Probe with a window long enough that a surviving "old" bucket would still be counted.
    const probe = await store.hit("old", PURGE_RETENTION_MS * 2, new Date(START.getTime() + later));

    expect(purgeSpy).toHaveBeenCalledOnce();
    expect(probe.count).toBe(1);
  });

  it("does not purge when the dice roll misses", async () => {
    const store = createMemoryStore();
    const purgeSpy = vi.spyOn(store, "purgeExpired");

    await createRateLimiter(store, { clock: clockAt(0), random: () => PURGE_PROBABILITY })(
      "k",
      options,
    );

    expect(purgeSpy).not.toHaveBeenCalled();
  });

  it("still answers when the purge fails", async () => {
    const store = createMemoryStore();
    vi.spyOn(store, "purgeExpired").mockRejectedValue(new Error("db down"));

    const result = await createRateLimiter(store, { clock: clockAt(0), random: () => 0 })(
      "k",
      options,
    );

    expect(result.isAllowed).toBe(true);
  });
});
