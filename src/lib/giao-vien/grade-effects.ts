import "server-only";
import type { Prisma } from "@/generated/prisma/client";
import type { Subject } from "@/generated/prisma/enums";
import { recordActivity, recordSubjectScore } from "@/lib/student/progress-records";
import { MAX_PARENTS_PER_STUDENT, PARENT_PORTAL_PATH } from "./constants";
import { formatScoreOutOf, toScoreOutOf10 } from "./grading";
import type { GradeInput } from "./schemas";

/** The submission facts the side effects of a grade need; selected once by save-grade. */
export interface GradedSubmission {
  readonly studentId: string;
  readonly multipleChoiceScore: number;
  readonly student: { readonly user: { readonly name: string } };
  readonly assessment: {
    readonly title: string;
    readonly subject: Subject;
    readonly maxScore: number;
    readonly essayMaxScore: number;
  };
}

const ACTIVITY_TAG_LABEL = "Đã chấm chi tiết";

function buildNotification(submission: GradedSubmission, input: GradeInput, userId: string) {
  const score = formatScoreOutOf(input.essayScore, submission.assessment.essayMaxScore);
  const feedback = input.feedback === "" ? "" : ` Lời phê của giáo viên: ${input.feedback}`;
  return {
    userId,
    kind: "GRADE_PUBLISHED" as const,
    title: `Điểm mới: ${submission.assessment.title}`,
    body: `${submission.student.user.name} được ${score} điểm phần tự luận.${feedback}`,
    href: PARENT_PORTAL_PATH,
  };
}

export async function notifyParents(
  tx: Prisma.TransactionClient,
  submission: GradedSubmission,
  input: GradeInput,
): Promise<number> {
  const links = await tx.parentChild.findMany({
    where: { studentId: submission.studentId },
    take: MAX_PARENTS_PER_STUDENT,
    select: { parent: { select: { userId: true } } },
  });
  const result = await tx.notification.createMany({
    data: links.map((link) => buildNotification(submission, input, link.parent.userId)),
  });
  return result.count;
}

/** Writes the student's activity entry and this week's subject score for a new or changed grade. */
export async function recordGradeProgress(
  tx: Prisma.TransactionClient,
  submission: GradedSubmission,
  input: GradeInput,
  at: Date,
): Promise<void> {
  const { assessment, studentId } = submission;
  const total = submission.multipleChoiceScore + input.essayScore;
  const feedback = input.feedback === "" ? "" : ` Lời phê của giáo viên: ${input.feedback}`;
  await recordActivity(tx, {
    studentId,
    kind: "EXAM_COMPLETED",
    title: `Giáo viên đã chấm bài: ${assessment.title}`,
    description: [
      { text: "Đạt kết quả " },
      { text: `${formatScoreOutOf(total, assessment.maxScore)} điểm`, isEmphasis: true },
      { text: `.${feedback}` },
    ],
    tags: [{ label: ACTIVITY_TAG_LABEL, tone: "neutral" }],
    occurredAt: at,
  });
  const scoreOutOf10 = toScoreOutOf10(total, assessment.maxScore);
  if (scoreOutOf10 === null) return;
  await recordSubjectScore(tx, { studentId, subject: assessment.subject, at, scoreOutOf10 });
}
