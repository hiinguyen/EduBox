import "server-only";
import { Prisma } from "@/generated/prisma/client";
import { assessmentsOfStudent } from "@/lib/auth/access";
import type { SessionUser } from "@/lib/auth/session";
import { db } from "@/lib/db";
import { rateLimit } from "@/lib/rate-limit";
import { fail, failFromZod, ok } from "@/lib/server/action-result";
import { START_RATE_LIMIT, START_RATE_LIMIT_KEY_PREFIX } from "./constants";
import { computeEndsAt } from "./deadline";
import { overdue } from "./exam-errors";
import { startAttemptInputSchema } from "./schemas";
import type { StartAttemptResult } from "./types";

/** Exams a student can sit: an online exam with a duration and at least one multiple choice question. */
export const TAKEABLE = {
  kind: "EXAM",
  durationMinutes: { not: null },
  questions: { some: { type: "MULTIPLE_CHOICE" } },
} as const satisfies Prisma.AssessmentWhereInput;

function findAttemptId(assessmentId: string, studentId: string) {
  return db.examAttempt.findUnique({
    where: { assessmentId_studentId: { assessmentId, studentId } },
    select: { id: true },
  });
}

/**
 * The only place an ExamAttempt is created. Idempotent: the unique (assessment, student)
 * constraint makes concurrent starts safe, the loser reads the winner's row so
 * `startedAt` and `endsAt` never change. Must run inside the caller's try block.
 */
export async function startAttemptFor(
  user: SessionUser,
  rawInput: unknown,
  now: Date = new Date(),
): Promise<StartAttemptResult> {
  const limit = await rateLimit(`${START_RATE_LIMIT_KEY_PREFIX}:${user.id}`, START_RATE_LIMIT);
  if (!limit.isAllowed) return fail("RATE_LIMITED");
  const parsed = startAttemptInputSchema.safeParse(rawInput);
  if (!parsed.success) return failFromZod(parsed.error);
  const { assessmentId } = parsed.data;
  const studentId = user.profileId;

  const exam = await db.assessment.findFirst({
    where: { AND: [{ id: assessmentId }, assessmentsOfStudent(studentId), TAKEABLE] },
    select: { durationMinutes: true, dueAt: true },
  });
  if (!exam || exam.durationMinutes === null) return fail("NOT_FOUND");
  const existing = await findAttemptId(assessmentId, studentId);
  if (existing) return ok({ attemptId: existing.id });
  if (exam.dueAt && exam.dueAt.getTime() <= now.getTime()) return overdue();

  try {
    const created = await db.examAttempt.create({
      data: {
        assessmentId,
        studentId,
        startedAt: now,
        endsAt: computeEndsAt(now, exam.durationMinutes, exam.dueAt),
      },
      select: { id: true },
    });
    return ok({ attemptId: created.id });
  } catch (error) {
    const isRace = error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002";
    const winner = isRace ? await findAttemptId(assessmentId, studentId) : null;
    if (!winner) throw error;
    return ok({ attemptId: winner.id });
  }
}
