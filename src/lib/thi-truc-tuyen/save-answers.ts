import "server-only";
import type { SessionUser } from "@/lib/auth/session";
import { db } from "@/lib/db";
import { rateLimit } from "@/lib/rate-limit";
import { failFromZod, fail, ok } from "@/lib/server/action-result";
import {
  areItemsValid,
  loadOptionsByQuestion,
  loadOwnedAttempt,
  writeAnswers,
} from "./attempt-guard";
import { SAVE_RATE_LIMIT, SAVE_RATE_LIMIT_KEY_PREFIX } from "./constants";
import { alreadySubmitted, deadlinePassed } from "./exam-errors";
import { finalizeIfExpired } from "./expire-attempts";
import { saveAnswersInputSchema } from "./schemas";
import type { SaveAnswersResult } from "./types";

/**
 * Stores a batch of answers for an in-progress attempt before its deadline.
 * The row lock taken by the guarded update serialises this against `submitAttempt`,
 * so an answer can never land after the attempt was finalised.
 * Must run inside the caller's try block: the rate limiter can throw.
 */
export async function saveAnswersFor(
  user: SessionUser,
  rawInput: unknown,
  now: Date = new Date(),
): Promise<SaveAnswersResult> {
  const limit = await rateLimit(`${SAVE_RATE_LIMIT_KEY_PREFIX}:${user.id}`, SAVE_RATE_LIMIT);
  if (!limit.isAllowed) return fail("RATE_LIMITED");
  const parsed = saveAnswersInputSchema.safeParse(rawInput);
  if (!parsed.success) return failFromZod(parsed.error);
  const { attemptId, answers, currentIndex } = parsed.data;

  const attempt = await loadOwnedAttempt(user.profileId, attemptId);
  if (!attempt) return fail("NOT_FOUND");
  if (attempt.status !== "IN_PROGRESS") return alreadySubmitted();
  if (now >= attempt.endsAt) {
    await finalizeIfExpired(attempt, now);
    return deadlinePassed();
  }

  const options = await loadOptionsByQuestion(attempt.assessmentId);
  const isIndexValid = currentIndex === undefined || currentIndex < options.size;
  if (!isIndexValid || !areItemsValid(answers, options)) return fail("INVALID_INPUT");

  const isSaved = await db.$transaction(async (tx) => {
    const claim = await tx.examAttempt.updateMany({
      where: { id: attempt.id, status: "IN_PROGRESS", endsAt: { gt: now } },
      data: { updatedAt: now, ...(currentIndex === undefined ? {} : { currentIndex }) },
    });
    if (claim.count === 0) return false;
    await writeAnswers(tx, attempt.id, answers, now);
    return true;
  });
  return isSaved ? ok({ savedAt: now.getTime() }) : deadlinePassed();
}
