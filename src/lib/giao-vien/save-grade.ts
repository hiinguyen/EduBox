import "server-only";
import type { Prisma } from "@/generated/prisma/client";
import { submissionsOfTeacher } from "@/lib/auth/access";
import type { SessionUser } from "@/lib/auth/session";
import { db } from "@/lib/db";
import { fail, ok, type ActionResult } from "@/lib/server/action-result";
import { notifyParents, recordGradeProgress } from "./grade-effects";
import { decideGradeEffects } from "./grading";
import { gradeInputSchema, isScoreWithinMax, type GradeInput } from "./schemas";

export interface SaveGradeData {
  readonly submissionId: string;
  readonly essayScore: number;
  readonly notifiedParents: number;
  readonly message: string;
}

export type SaveGradeResult = ActionResult<SaveGradeData>;

export const SAVE_GRADE_MESSAGES = {
  invalidInput: "Điểm hoặc lời phê không hợp lệ. Vui lòng kiểm tra lại.",
  scoreAboveMax: "Điểm tự luận vượt quá thang điểm của bài kiểm tra.",
  // One message for "does not exist" and "belongs to someone else": it must not reveal which.
  notFound: "Không tìm thấy bài nộp này trong các lớp bạn phụ trách.",
  invalidSubmission: "Bài nộp không thuộc lớp của bài kiểm tra nên không thể chấm.",
  saved: "Đã lưu điểm vào hệ thống.",
  alreadyNotified: "Đã lưu điểm. Phụ huynh đã nhận thông báo về mức điểm này trước đó.",
  notifiedNobody:
    "Đã lưu điểm vào hệ thống. Học sinh chưa liên kết phụ huynh nên chưa có thông báo nào được gửi.",
} as const;

function describeSaved(notifiedParents: number, outcome: SavedOutcome): string {
  if (!outcome.isNoticeRequested) return SAVE_GRADE_MESSAGES.saved;
  if (!outcome.isNoticeSent) return SAVE_GRADE_MESSAGES.alreadyNotified;
  if (notifiedParents === 0) return SAVE_GRADE_MESSAGES.notifiedNobody;
  return `Đã lưu điểm và gửi thông báo trong ứng dụng cho ${notifiedParents} phụ huynh.`;
}

interface SavedOutcome {
  readonly isNoticeRequested: boolean;
  readonly isNoticeSent: boolean;
}

const SUBMISSION_SELECT = {
  id: true,
  studentId: true,
  multipleChoiceScore: true,
  student: { select: { user: { select: { name: true } } } },
  assessment: {
    select: { title: true, classId: true, subject: true, maxScore: true, essayMaxScore: true },
  },
  grade: { select: { essayScore: true, notifiedAt: true } },
} satisfies Prisma.SubmissionSelect;

type GradableSubmission = Prisma.SubmissionGetPayload<{ select: typeof SUBMISSION_SELECT }>;

async function findInvalidReason(
  tx: Prisma.TransactionClient,
  submission: GradableSubmission,
  input: GradeInput,
): Promise<SaveGradeResult | null> {
  const enrolled = await tx.enrollment.count({
    where: { classId: submission.assessment.classId, studentId: submission.studentId },
  });
  if (enrolled === 0) return fail("INVALID_INPUT", SAVE_GRADE_MESSAGES.invalidSubmission);
  if (!isScoreWithinMax(input.essayScore, submission.assessment.essayMaxScore)) {
    return fail("INVALID_INPUT", SAVE_GRADE_MESSAGES.scoreAboveMax);
  }
  return null;
}

function writeGrade(
  tx: Prisma.TransactionClient,
  params: {
    readonly teacherId: string;
    readonly submissionId: string;
    readonly input: GradeInput;
    readonly now: Date;
    readonly isNoticeSent: boolean;
  },
) {
  const { teacherId, submissionId, input, now, isNoticeSent } = params;
  const fields = {
    gradedById: teacherId,
    essayScore: input.essayScore,
    feedback: input.feedback === "" ? null : input.feedback,
    gradedAt: now,
  };
  return tx.grade.upsert({
    where: { submissionId },
    create: { submissionId, ...fields, notifiedAt: isNoticeSent ? now : null },
    update: { ...fields, ...(isNoticeSent ? { notifiedAt: now } : {}) },
  });
}

async function persistGrade(teacherId: string, input: GradeInput): Promise<SaveGradeResult> {
  return db.$transaction(async (tx) => {
    const submission = await tx.submission.findFirst({
      where: { AND: [submissionsOfTeacher(teacherId), { id: input.submissionId }] },
      select: SUBMISSION_SELECT,
    });
    if (!submission) return fail("NOT_FOUND", SAVE_GRADE_MESSAGES.notFound);
    const invalid = await findInvalidReason(tx, submission, input);
    if (invalid) return invalid;

    const now = new Date();
    const effects = decideGradeEffects(submission.grade, input);
    const isNoticeSent = effects.shouldNotifyParents;
    await writeGrade(tx, { teacherId, submissionId: submission.id, input, now, isNoticeSent });
    if (effects.hasScoreChanged) await recordGradeProgress(tx, submission, input, now);
    const notifiedParents = isNoticeSent ? await notifyParents(tx, submission, input) : 0;
    return ok({
      submissionId: submission.id,
      essayScore: input.essayScore,
      notifiedParents,
      message: describeSaved(notifiedParents, {
        isNoticeRequested: input.shouldNotifyParent,
        isNoticeSent,
      }),
    });
  });
}

/**
 * Validates, authorizes and stores one grade. The caller has already proven the user is a
 * teacher. A submission outside the teacher's classes and a missing one share one answer.
 */
export async function saveGrade(user: SessionUser, input: unknown): Promise<SaveGradeResult> {
  const parsed = gradeInputSchema.safeParse(input);
  if (!parsed.success) return fail("INVALID_INPUT", SAVE_GRADE_MESSAGES.invalidInput);
  return persistGrade(user.profileId, parsed.data);
}
