import "server-only";
import type { Prisma } from "@/generated/prisma/client";
import type { ActivityDescriptionSegment, ActivityTag } from "@/lib/student/progress-records";
import { recordActivity, recordStudyTime } from "@/lib/student/progress-records";
import { computeCourseProgress, computeCreditedSeconds } from "./progress-math";

type Tx = Prisma.TransactionClient;

export interface LessonProgressView {
  readonly positionSeconds: number;
  readonly isCompleted: boolean;
}

export interface ProgressWrite {
  readonly studentId: string;
  readonly lessonId: string;
  readonly positionSeconds: number;
  readonly isCompleted: boolean | undefined;
  readonly now: Date;
}

export interface ProgressOutcome {
  readonly view: LessonProgressView;
  readonly creditedSeconds: number;
  readonly isFirstView: boolean;
  readonly isFirstCompletion: boolean;
  readonly hasCompletionChanged: boolean;
}

const SECONDS_PER_MINUTE = 60;
const viewSelect = { positionSeconds: true, isCompleted: true } as const;

/** Flips the flag only when it was unset, so concurrent saves record the first completion once. */
async function flipToCompleted(tx: Tx, studentId: string, lessonId: string): Promise<boolean> {
  const flipped = await tx.lessonProgress.updateMany({
    where: { studentId, lessonId, isCompleted: false },
    data: { isCompleted: true },
  });
  return flipped.count === 1;
}

export async function writeProgress(tx: Tx, write: ProgressWrite): Promise<ProgressOutcome> {
  const { studentId, lessonId, positionSeconds, isCompleted, now } = write;
  const key = { studentId_lessonId: { studentId, lessonId } };
  const previous = await tx.lessonProgress.findUnique({
    where: key,
    select: { ...viewSelect, updatedAt: true },
  });
  const created = previous
    ? null
    : await tx.lessonProgress.createMany({
        data: [{ studentId, lessonId, positionSeconds, isCompleted: isCompleted ?? false }],
        skipDuplicates: true,
      });
  const isFirstView = created?.count === 1;
  const isFirstCompletion =
    isCompleted === true && (isFirstView || (await flipToCompleted(tx, studentId, lessonId)));
  const view = isFirstView
    ? { positionSeconds, isCompleted: isCompleted ?? false }
    : await tx.lessonProgress.update({
        where: key,
        data: { positionSeconds, ...(isCompleted === undefined ? {} : { isCompleted }) },
        select: viewSelect,
      });
  const isUncompleted = isCompleted === false && previous?.isCompleted === true;

  return {
    view,
    creditedSeconds: computeCreditedSeconds({ previous, positionSeconds, now }),
    isFirstView,
    isFirstCompletion,
    hasCompletionChanged: isFirstCompletion || isUncompleted,
  };
}

/** One progress query plus one enrollment read: no per-lesson round trips. */
export async function syncCourseEnrollment(
  tx: Tx,
  studentId: string,
  courseId: string,
): Promise<void> {
  const [enrollment, completed] = await Promise.all([
    tx.courseEnrollment.findUnique({
      where: { courseId_studentId: { courseId, studentId } },
      select: { course: { select: { lessonCount: true } } },
    }),
    tx.lessonProgress.findMany({
      where: { studentId, isCompleted: true, lesson: { courseId } },
      select: { lesson: { select: { number: true } } },
    }),
  ]);
  if (!enrollment) return;

  const progress = computeCourseProgress(
    completed.map((row) => row.lesson.number),
    enrollment.course.lessonCount,
  );
  await tx.courseEnrollment.update({
    where: { courseId_studentId: { courseId, studentId } },
    data: progress,
  });
}

export interface LectureActivity {
  readonly title: string;
  readonly description: ActivityDescriptionSegment[];
  readonly tags: ActivityTag[];
}

export function buildLectureActivity(title: string, durationSeconds: number): LectureActivity {
  const minutes = Math.max(1, Math.round(durationSeconds / SECONDS_PER_MINUTE));
  return {
    title: `Xem hết bài giảng "${title}"`,
    description: [
      { text: "Thời lượng bài giảng: " },
      { text: `${minutes} phút`, isEmphasis: true },
      { text: "." },
    ],
    tags: [{ label: "Hoàn thành 100% video", tone: "success" }],
  };
}

/** Saves the position and, in the same transaction, keeps every dashboard table in step. */
export async function commitProgress(tx: Tx, write: ProgressWrite): Promise<LessonProgressView> {
  const { studentId, lessonId, now } = write;
  const lesson = await tx.lesson.findUniqueOrThrow({
    where: { id: lessonId },
    select: { title: true, courseId: true, durationSeconds: true },
  });
  const outcome = await writeProgress(tx, write);
  if (outcome.isFirstView) {
    await tx.lesson.update({ where: { id: lessonId }, data: { viewCount: { increment: 1 } } });
  }
  await recordStudyTime(tx, { studentId, at: now, seconds: outcome.creditedSeconds });
  if (outcome.isFirstCompletion) {
    const activity = buildLectureActivity(lesson.title, lesson.durationSeconds);
    await recordActivity(tx, { studentId, kind: "LECTURE_WATCHED", occurredAt: now, ...activity });
  }
  if (lesson.courseId && outcome.hasCompletionChanged) {
    await syncCourseEnrollment(tx, studentId, lesson.courseId);
  }
  return outcome.view;
}
