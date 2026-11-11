export interface RateLimitOptions {
  readonly limit: number;
  readonly windowMs: number;
}

export interface RateLimitResult {
  readonly isAllowed: boolean;
  readonly remaining: number;
  readonly retryAfterMs: number;
}

export interface WindowHit {
  readonly count: number;
  readonly windowStart: Date;
}

/** Records one hit for `key` and returns the counter of the window it fell into. */
export interface RateLimitStore {
  hit(key: string, windowMs: number, now: Date): Promise<WindowHit>;
  /** Deletes buckets whose window started before `cutoff`; returns how many were removed. */
  purgeExpired(cutoff: Date): Promise<number>;
}

/** Chance per hit of running the opportunistic purge (no cron is available). */
export const PURGE_PROBABILITY = 0.01;
/**
 * Buckets untouched for this long are deleted. It must exceed the longest window any
 * caller uses (the longest today is 15 minutes).
 */
export const PURGE_RETENTION_MS = 24 * 60 * 60 * 1000;

/** Pure decision: given the counter after this hit, is the request allowed? */
export function evaluateWindow(
  hit: WindowHit,
  options: RateLimitOptions,
  now: Date,
): RateLimitResult {
  const windowEnd = hit.windowStart.getTime() + options.windowMs;
  const retryAfterMs = Math.max(0, windowEnd - now.getTime());
  const remaining = Math.max(0, options.limit - hit.count);

  return { isAllowed: hit.count <= options.limit, remaining, retryAfterMs };
}

export interface RateLimiterOptions {
  readonly clock?: () => Date;
  /** Uniform random source in [0, 1); injectable so the purge is testable. */
  readonly random?: () => number;
}

export function createRateLimiter(
  store: RateLimitStore,
  { clock = () => new Date(), random = Math.random }: RateLimiterOptions = {},
) {
  return async function rateLimit(
    key: string,
    options: RateLimitOptions,
  ): Promise<RateLimitResult> {
    const now = clock();
    const hit = await store.hit(key, options.windowMs, now);

    if (random() < PURGE_PROBABILITY) {
      // Best effort: a failed purge must never fail or slow the guarded request's decision.
      await store.purgeExpired(new Date(now.getTime() - PURGE_RETENTION_MS)).catch(() => 0);
    }
    return evaluateWindow(hit, options, now);
  };
}
