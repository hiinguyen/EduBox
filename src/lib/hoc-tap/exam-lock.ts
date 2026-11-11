import "server-only";
import { attemptsOfStudent } from "@/lib/auth/access";
import { db } from "@/lib/db";

export const EXAM_LOCK_MESSAGE = "Bạn đang làm bài thi, trợ lý AI tạm khóa.";

/** True while the student has an unfinished attempt whose time has not run out. */
export async function hasActiveExamAttempt(studentId: string, now: Date): Promise<boolean> {
  const count = await db.examAttempt.count({
    where: {
      AND: [attemptsOfStudent(studentId), { status: "IN_PROGRESS", endsAt: { gt: now } }],
    },
  });
  return count > 0;
}
