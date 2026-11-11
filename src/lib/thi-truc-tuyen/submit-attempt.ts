import "server-only";
import type { SessionUser } from "@/lib/auth/session";
import { rateLimit } from "@/lib/rate-limit";
import { fail, failFromZod, ok } from "@/lib/server/action-result";
import { logServerError } from "@/lib/server/log";
import { areItemsValid, loadOptionsByQuestion, loadOwnedAttempt } from "./attempt-guard";
import { SUBMIT_GRACE_MS, SUBMIT_RATE_LIMIT, SUBMIT_RATE_LIMIT_KEY_PREFIX } from "./constants";
import { finalizeAttempt, isSubmissionCodeClash, isUniqueViolation } from "./finalize-attempt";
import type { FinalStatus } from "./finalize-attempt";
import { readReceipt } from "./receipt";
import { submitAttemptInputSchema } from "./schemas";
import type { SubmitAttemptResult } from "./types";

/**
 * Finalises an attempt. Idempotent: a second call returns the first result.
 * Final answers are taken only until `endsAt` plus the grace period; after that the
 * server finalises with what it already stored and marks the attempt EXPIRED.
 */
export async function submitAttemptFor(
  user: SessionUser,
  rawInput: unknown,
  now: Date = new Date(),
): Promise<SubmitAttemptResult> {
  const limit = await rateLimit(`${SUBMIT_RATE_LIMIT_KEY_PREFIX}:${user.id}`, SUBMIT_RATE_LIMIT);
  if (!limit.isAllowed) return fail("RATE_LIMITED");
  const parsed = submitAttemptInputSchema.safeParse(rawInput);
  if (!parsed.success) return failFromZod(parsed.error);

  const attempt = await loadOwnedAttempt(user.profileId, parsed.data.attemptId);
  if (!attempt) return fail("NOT_FOUND");
  const existing = await readReceipt(attempt.id, attempt.status);
  if (existing) return ok({ receipt: existing });

  const isLate = now.getTime() > attempt.endsAt.getTime() + SUBMIT_GRACE_MS;
  const items = isLate ? [] : parsed.data.answers;
  const options = await loadOptionsByQuestion(attempt.assessmentId);
  if (!areItemsValid(items, options)) return fail("INVALID_INPUT");

  const status: FinalStatus = isLate ? "EXPIRED" : "SUBMITTED";
  const at = isLate ? attempt.endsAt : now;
  try {
    const receipt = await finalizeAttempt({ attempt, status, items, at });
    if (receipt) return ok({ receipt });
  } catch (error) {
    if (!isUniqueViolation(error)) throw error;
    logServerError("thi-truc-tuyen.submit", error, { attemptId: attempt.id });
    // The transaction rolled back, so the attempt is still open and can be submitted again.
    return isSubmissionCodeClash(error) ? fail("INTERNAL") : fail("CONFLICT");
  }

  const settled = await loadOwnedAttempt(user.profileId, attempt.id);
  const winner = settled && (await readReceipt(settled.id, settled.status));
  return winner ? ok({ receipt: winner }) : fail("INTERNAL");
}
