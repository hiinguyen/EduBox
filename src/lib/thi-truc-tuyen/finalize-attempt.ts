import "server-only";
import { randomInt } from "node:crypto";
import { Prisma } from "@/generated/prisma/client";
import { db } from "@/lib/db";
import { roundTo } from "@/lib/format/number";
import { recordActivity, recordSubjectScore } from "@/lib/student/progress-records";
import { writeAnswers } from "./attempt-guard";
import type { OwnedAttempt } from "./attempt-guard";
import {
  SCORE_SCALE,
  SUBMISSION_CODE_ATTEMPTS,
  SUBMISSION_CODE_COLUMN,
  SUBMISSION_CODE_MIN,
  SUBMISSION_CODE_PREFIX,
  SUBMISSION_CODE_RANGE,
} from "./constants";
import { gradeMultipleChoice, isFullyAutoGradable } from "./grading";
import { buildExamActivity } from "./exam-activity";
import type { SaveItem } from "./sync";
import type { SubmissionReceipt } from "./types";

export type FinalStatus = SubmissionReceipt["status"];

export interface FinalizeInput {
  readonly attempt: OwnedAttempt;
  readonly status: FinalStatus;
  readonly items: readonly SaveItem[];
  /** When the work counts as handed in: the request time, or the deadline for an expired attempt. */
  readonly at: Date;
}

interface GradedAttempt {
  readonly score: number;
  readonly correctCount: number;
  readonly totalCount: number;
  readonly isComplete: boolean;
}

function newSubmissionCode(): string {
  return `${SUBMISSION_CODE_PREFIX}${SUBMISSION_CODE_MIN + randomInt(SUBMISSION_CODE_RANGE)}`;
}

/** Grades the answers stored for the attempt against the server-side key. */
async function gradeStoredAnswers(
  tx: Prisma.TransactionClient,
  attempt: OwnedAttempt,
): Promise<GradedAttempt> {
  const where = { assessmentId: attempt.assessmentId };
  const stored = await tx.attemptAnswer.findMany({
    where: { attemptId: attempt.id },
    select: { questionId: true, optionId: true },
  });
  const questions = await tx.question.findMany({
    where: { ...where, type: "MULTIPLE_CHOICE" },
    select: { id: true, points: true, key: { select: { optionId: true } } },
  });
  const essayCount = await tx.question.count({ where: { ...where, type: "ESSAY" } });
  const graded = gradeMultipleChoice({
    questions,
    keys: Object.fromEntries(questions.flatMap((q) => (q.key ? [[q.id, q.key.optionId]] : []))),
    answers: Object.fromEntries(stored.map((row) => [row.questionId, row.optionId])),
  });
  const isComplete = isFullyAutoGradable({
    essayMaxScore: attempt.assessment.essayMaxScore,
    hasEssayQuestions: essayCount > 0,
  });
  return { ...graded, isComplete };
}

async function recordProgress(
  tx: Prisma.TransactionClient,
  input: FinalizeInput,
  graded: GradedAttempt,
): Promise<void> {
  const { attempt, at, status } = input;
  const { studentId } = attempt;
  await recordActivity(tx, {
    studentId,
    ...buildExamActivity({ title: attempt.assessment.title, status, ...graded }),
    occurredAt: at,
  });
  const { maxScore, subject } = attempt.assessment;
  if (!graded.isComplete || maxScore <= 0) return;
  await recordSubjectScore(tx, {
    studentId,
    subject,
    at,
    scoreOutOf10: roundTo((graded.score / maxScore) * SCORE_SCALE, 1),
  });
}

/** Claims the attempt, grades it and creates the submission; a Grade only when nothing is left to mark. */
async function finalizeOnce(input: FinalizeInput): Promise<SubmissionReceipt | null> {
  const { attempt, status, items, at } = input;
  return db.$transaction(async (tx) => {
    const claim = await tx.examAttempt.updateMany({
      where: { id: attempt.id, status: "IN_PROGRESS" },
      data: { status, submittedAt: at },
    });
    if (claim.count === 0) return null;
    await writeAnswers(tx, attempt.id, items, at);

    const graded = await gradeStoredAnswers(tx, attempt);
    const submission = await tx.submission.create({
      data: {
        assessmentId: attempt.assessmentId,
        studentId: attempt.studentId,
        attemptId: attempt.id,
        code: newSubmissionCode(),
        multipleChoiceScore: graded.score,
        submittedAt: at,
      },
      select: { id: true },
    });
    if (graded.isComplete) {
      await tx.grade.create({
        data: {
          submissionId: submission.id,
          gradedById: attempt.assessment.creatorId,
          essayScore: 0,
          gradedAt: at,
        },
      });
    }
    await recordProgress(tx, input, graded);
    return { status, submittedAt: at.getTime(), isPendingReview: !graded.isComplete };
  });
}

export function isUniqueViolation(error: unknown): error is Prisma.PrismaClientKnownRequestError {
  return error instanceof Prisma.PrismaClientKnownRequestError && error.code === "P2002";
}

const CODE_NAME_PATTERN = new RegExp(`(^|_)${SUBMISSION_CODE_COLUMN}(_|$)`);

/** Reads the violated index or columns from `meta.target` or, with the pg driver adapter, from its error cause. */
function violatedConstraintNames(error: Prisma.PrismaClientKnownRequestError): string[] {
  const meta = error.meta as
    | {
        target?: unknown;
        driverAdapterError?: {
          cause?: { constraint?: { index?: string; fields?: readonly string[] } };
        };
      }
    | undefined;
  const target = Array.isArray(meta?.target) ? meta.target : [meta?.target];
  const constraint = meta?.driverAdapterError?.cause?.constraint;
  return [...target, constraint?.index, ...(constraint?.fields ?? [])].filter(
    (name): name is string => typeof name === "string",
  );
}

/** True only for a clash on the random submission code; any other unique violation is a real conflict. */
export function isSubmissionCodeClash(error: unknown): boolean {
  if (!isUniqueViolation(error)) return false;
  return violatedConstraintNames(error).some((name) => CODE_NAME_PATTERN.test(name));
}

/**
 * Finalises exactly once (the transaction rolls back on any failure, leaving the attempt open).
 * Retries only the random code collision; every other error surfaces to the caller.
 */
export async function finalizeAttempt(input: FinalizeInput): Promise<SubmissionReceipt | null> {
  for (let attemptNumber = 1; ; attemptNumber += 1) {
    try {
      return await finalizeOnce(input);
    } catch (error) {
      const isLastAttempt = attemptNumber >= SUBMISSION_CODE_ATTEMPTS;
      if (!isSubmissionCodeClash(error) || isLastAttempt) throw error;
    }
  }
}
