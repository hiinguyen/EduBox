import type { RateLimitStore, WindowHit } from "./fixed-window";

/**
 * Process-local store for tests. It is NOT shared across server instances,
 * so production code must use the Postgres store.
 */
export function createMemoryStore(): RateLimitStore {
  const buckets = new Map<string, WindowHit>();

  return {
    async hit(key, windowMs, now) {
      const current = buckets.get(key);
      const isExpired = !current || current.windowStart.getTime() + windowMs <= now.getTime();
      const next: WindowHit = isExpired
        ? { count: 1, windowStart: now }
        : { count: current.count + 1, windowStart: current.windowStart };

      buckets.set(key, next);
      return next;
    },
    async purgeExpired(cutoff) {
      let removed = 0;
      for (const [key, bucket] of buckets) {
        if (bucket.windowStart.getTime() < cutoff.getTime()) {
          buckets.delete(key);
          removed += 1;
        }
      }
      return removed;
    },
  };
}
