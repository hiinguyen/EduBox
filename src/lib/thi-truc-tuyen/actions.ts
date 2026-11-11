"use server";

import { requireRoleForAction } from "@/lib/auth/session";
import type { SessionUser } from "@/lib/auth/session";
import { fail, failFromAuth } from "@/lib/server/action-result";
import type { ActionResult } from "@/lib/server/action-result";
import { logServerError } from "@/lib/server/log";
import { saveAnswersFor } from "./save-answers";
import { startAttemptFor } from "./start-attempt";
import { submitAttemptFor } from "./submit-attempt";
import type { SaveAnswersResult, StartAttemptResult, SubmitAttemptResult } from "./types";

type ExamHandler<T> = (user: SessionUser, input: unknown) => Promise<ActionResult<T>>;

/** Auth, then the handler inside one try: a limiter or database failure becomes INTERNAL. */
async function run<T>(
  scope: string,
  input: unknown,
  handler: ExamHandler<T>,
): Promise<ActionResult<T>> {
  const auth = await requireRoleForAction("STUDENT");
  if (!auth.ok) return failFromAuth(auth.error);
  try {
    return await handler(auth.user, input);
  } catch (error) {
    logServerError(scope, error, { userId: auth.user.id });
    return fail("INTERNAL");
  }
}

export async function startAttempt(input: unknown): Promise<StartAttemptResult> {
  return run("thi-truc-tuyen.start", input, (user, raw) => startAttemptFor(user, raw));
}

export async function saveAnswers(input: unknown): Promise<SaveAnswersResult> {
  return run("thi-truc-tuyen.save", input, (user, raw) => saveAnswersFor(user, raw));
}

export async function submitAttempt(input: unknown): Promise<SubmitAttemptResult> {
  return run("thi-truc-tuyen.submit", input, (user, raw) => submitAttemptFor(user, raw));
}
