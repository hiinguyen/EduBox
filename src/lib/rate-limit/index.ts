import { createRateLimiter } from "./fixed-window";
import { postgresStore } from "./postgres-store";

export type { RateLimitOptions, RateLimitResult } from "./fixed-window";

/**
 * Fixed-window limiter backed by Postgres.
 * `key` must not contain raw PII: use a namespace plus an id or hashed value.
 */
export const rateLimit = createRateLimiter(postgresStore);
