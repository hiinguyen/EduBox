import "server-only";
import { db } from "@/lib/db";
import type { SubmissionReceipt } from "./types";

/** The receipt of a finished attempt, or null while it is in progress or has no submission. */
export async function readReceipt(
  attemptId: string,
  status: "IN_PROGRESS" | SubmissionReceipt["status"],
): Promise<SubmissionReceipt | null> {
  if (status === "IN_PROGRESS") return null;
  const submission = await db.submission.findUnique({
    where: { attemptId },
    select: { submittedAt: true, grade: { select: { submissionId: true } } },
  });
  if (!submission) return null;
  return {
    status,
    submittedAt: submission.submittedAt.getTime(),
    isPendingReview: submission.grade === null,
  };
}
