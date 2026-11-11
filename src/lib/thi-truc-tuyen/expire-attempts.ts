import "server-only";
import { db } from "@/lib/db";
import { OWNED_ATTEMPT_SELECT } from "./attempt-guard";
import type { OwnedAttempt } from "./attempt-guard";
import { DEFAULT_EXPIRY_BATCH_SIZE, SUBMIT_GRACE_MS } from "./constants";
import { finalizeAttempt } from "./finalize-attempt";

/** An open attempt is past the point where the server still takes final answers. */
export function isPastGrace(attempt: Pick<OwnedAttempt, "status" | "endsAt">, now: Date): boolean {
  return (
    attempt.status === "IN_PROGRESS" && now.getTime() > attempt.endsAt.getTime() + SUBMIT_GRACE_MS
  );
}

/**
 * Marks an overdue attempt EXPIRED and creates its Submission from the stored answers.
 * Idempotent: a concurrent finaliser wins the claim and this call returns false.
 */
export async function finalizeIfExpired(attempt: OwnedAttempt, now: Date): Promise<boolean> {
  if (!isPastGrace(attempt, now)) return false;
  const receipt = await finalizeAttempt({
    attempt,
    status: "EXPIRED",
    items: [],
    at: attempt.endsAt,
  });
  return receipt !== null;
}

/**
 * Finalises up to `limit` overdue attempts across all students, oldest deadline first.
 * Built for a scheduled job; returns how many attempts this call finalised.
 */
export async function finalizeExpiredAttempts(
  now: Date,
  limit: number = DEFAULT_EXPIRY_BATCH_SIZE,
): Promise<number> {
  const overdue = await db.examAttempt.findMany({
    where: {
      status: "IN_PROGRESS",
      endsAt: { lt: new Date(now.getTime() - SUBMIT_GRACE_MS) },
    },
    orderBy: { endsAt: "asc" },
    take: limit,
    select: OWNED_ATTEMPT_SELECT,
  });
  let finalized = 0;
  for (const attempt of overdue) {
    if (await finalizeIfExpired(attempt, now)) finalized += 1;
  }
  return finalized;
}
