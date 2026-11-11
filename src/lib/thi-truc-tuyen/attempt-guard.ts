import "server-only";
import type { Prisma } from "@/generated/prisma/client";
import { assessmentsOfStudent, attemptsOfStudent } from "@/lib/auth/access";
import { db } from "@/lib/db";
import { MAX_QUESTIONS_PER_EXAM } from "./constants";
import type { SaveItem } from "./sync";

export const OWNED_ATTEMPT_SELECT = {
  id: true,
  assessmentId: true,
  studentId: true,
  status: true,
  endsAt: true,
  assessment: {
    select: { essayMaxScore: true, creatorId: true, subject: true, title: true, maxScore: true },
  },
} satisfies Prisma.ExamAttemptSelect;

export type OwnedAttempt = Prisma.ExamAttemptGetPayload<{ select: typeof OWNED_ATTEMPT_SELECT }>;

/**
 * One scoped read for authorization and data. An open attempt needs the exam to be
 * published and the student still enrolled; a finished attempt stays readable so a
 * retried submit still returns its receipt after the exam was closed.
 * Null both for unknown attempts and for attempts of other students, so ids cannot be probed.
 */
export function loadOwnedAttempt(
  studentId: string,
  attemptId: string,
): Promise<OwnedAttempt | null> {
  return db.examAttempt.findFirst({
    where: {
      AND: [
        { id: attemptId },
        attemptsOfStudent(studentId),
        {
          OR: [{ status: { not: "IN_PROGRESS" } }, { assessment: assessmentsOfStudent(studentId) }],
        },
      ],
    },
    select: OWNED_ATTEMPT_SELECT,
  });
}

export type OptionsByQuestion = ReadonlyMap<string, ReadonlySet<string>>;

/** Option ids per multiple choice question. Never selects AnswerKey. */
export async function loadOptionsByQuestion(assessmentId: string): Promise<OptionsByQuestion> {
  const questions = await db.question.findMany({
    where: { assessmentId, type: "MULTIPLE_CHOICE" },
    select: { id: true, options: { select: { id: true } } },
    take: MAX_QUESTIONS_PER_EXAM,
  });
  return new Map(
    questions.map((question) => [question.id, new Set(question.options.map((o) => o.id))]),
  );
}

/** Every question must belong to the exam and every option to its own question. */
export function areItemsValid(items: readonly SaveItem[], options: OptionsByQuestion): boolean {
  return items.every((item) => {
    const allowed = options.get(item.questionId);
    return allowed !== undefined && (item.optionId === null || allowed.has(item.optionId));
  });
}

/**
 * Writes the whole batch in one statement so the attempt row lock is held for a single round trip.
 * Every value is a bound parameter (arrays are unnested), never interpolated SQL.
 */
export async function writeAnswers(
  tx: Prisma.TransactionClient,
  attemptId: string,
  items: readonly SaveItem[],
  now: Date,
): Promise<void> {
  if (items.length === 0) return;
  const questionIds = items.map((item) => item.questionId);
  const optionIds = items.map((item) => item.optionId);
  const flags = items.map((item) => item.isFlagged);
  await tx.$executeRaw`
    INSERT INTO "AttemptAnswer" ("attemptId", "questionId", "optionId", "isFlagged", "answeredAt")
    SELECT ${attemptId}, batch."questionId", batch."optionId", batch."isFlagged", ${now}
    FROM unnest(${questionIds}::text[], ${optionIds}::text[], ${flags}::boolean[])
      AS batch("questionId", "optionId", "isFlagged")
    ON CONFLICT ("attemptId", "questionId") DO UPDATE SET
      "optionId" = EXCLUDED."optionId",
      "isFlagged" = EXCLUDED."isFlagged",
      "answeredAt" = EXCLUDED."answeredAt"`;
}
