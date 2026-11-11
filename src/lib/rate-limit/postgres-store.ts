import { db } from "@/lib/db";
import type { RateLimitStore, WindowHit } from "./fixed-window";

interface BucketRow {
  readonly count: number;
  readonly windowStart: Date;
}

/**
 * One atomic upsert per hit: a row older than the window restarts at 1, otherwise the
 * counter increments. Safe under concurrent requests and across server instances.
 */
export const postgresStore: RateLimitStore = {
  async hit(key, windowMs, now): Promise<WindowHit> {
    const cutoff = new Date(now.getTime() - windowMs);
    const rows = await db.$queryRaw<BucketRow[]>`
      INSERT INTO "RateLimitBucket" ("key", "count", "windowStart")
      VALUES (${key}, 1, ${now})
      ON CONFLICT ("key") DO UPDATE SET
        "count" = CASE WHEN "RateLimitBucket"."windowStart" <= ${cutoff}
                       THEN 1 ELSE "RateLimitBucket"."count" + 1 END,
        "windowStart" = CASE WHEN "RateLimitBucket"."windowStart" <= ${cutoff}
                             THEN ${now} ELSE "RateLimitBucket"."windowStart" END
      RETURNING "count", "windowStart"
    `;
    const row = rows[0];

    if (!row) {
      throw new Error("Rate limit upsert returned no row");
    }

    return { count: row.count, windowStart: row.windowStart };
  },
  async purgeExpired(cutoff): Promise<number> {
    const result = await db.rateLimitBucket.deleteMany({ where: { windowStart: { lt: cutoff } } });
    return result.count;
  },
};
