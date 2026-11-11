import "server-only";
import {
  activityOfParent,
  assessmentsOfParent,
  chatThreadsOfStudent,
  childrenOfParent,
  contactBookOfParent,
  submissionsOfParent,
  upcomingAssessmentsOfStudent,
} from "@/lib/auth/access";
import { db } from "@/lib/db";
import { MS_PER_DAY } from "@/lib/format/time";
import { startOfVnWeek } from "@/lib/format/date";
import {
  ACTIVITY_LIMIT,
  BADGE_RECENT_DAYS,
  CHART_WEEKS,
  DEVICES_LIMIT,
  GRADE_WINDOW_DAYS,
  RECENT_GRADES_LIMIT,
  STUDY_LOOKBACK_DAYS,
  UPCOMING_LIMIT,
} from "./constants";
import type { StudyDaySample } from "./effort";
import { CHART_SUBJECTS } from "./progress-report";
import type { GradeSample } from "./stats";
import { currentWeekRange, lookbackStart } from "./study-window";

/*
 * Every function takes the parent's profile id and a student id, and ANDs an access.ts
 * fragment into its query (directly, or through `ownChild` for models that have a `student`
 * relation), so a caller mistake cannot reach a child the parent does not own.
 */

/** Scopes a query on a student-owned model to one of the parent's own children. */
export function ownChild(parentId: string, studentId: string) {
  return { studentId, student: childrenOfParent(parentId) };
}

function daysAgo(now: Date, days: number): Date {
  return new Date(now.getTime() - days * MS_PER_DAY);
}

export async function loadStudiedSeconds(
  parentId: string,
  studentId: string,
  now: Date,
): Promise<number> {
  const { from, to } = currentWeekRange(now);
  const total = await db.studyDay.aggregate({
    where: { ...ownChild(parentId, studentId), day: { gte: from, lte: to } },
    _sum: { studiedSeconds: true },
  });
  return total._sum.studiedSeconds ?? 0;
}

export async function loadStudyDays(
  parentId: string,
  studentId: string,
  now: Date,
): Promise<StudyDaySample[]> {
  return db.studyDay.findMany({
    where: {
      ...ownChild(parentId, studentId),
      day: { gte: lookbackStart(now, STUDY_LOOKBACK_DAYS) },
    },
    orderBy: { day: "desc" },
    take: STUDY_LOOKBACK_DAYS + 1,
    select: { day: true, studiedSeconds: true },
  });
}

export interface LessonCounts {
  readonly watched: number;
  readonly completed: number;
}

export async function loadLessonCounts(
  parentId: string,
  studentId: string,
  now: Date,
): Promise<LessonCounts> {
  const groups = await db.lessonProgress.groupBy({
    by: ["isCompleted"],
    where: { ...ownChild(parentId, studentId), updatedAt: { gte: startOfVnWeek(now) } },
    _count: { _all: true },
  });
  const completed = groups.find((group) => group.isCompleted)?._count._all ?? 0;
  const total = groups.reduce((sum, group) => sum + group._count._all, 0);
  return { watched: total, completed };
}

export async function loadGradeSamples(
  parentId: string,
  studentId: string,
  now: Date,
): Promise<GradeSample[]> {
  const rows = await db.submission.findMany({
    where: {
      AND: [
        submissionsOfParent(parentId),
        { studentId, grade: { is: { gradedAt: { gte: daysAgo(now, GRADE_WINDOW_DAYS) } } } },
      ],
    },
    orderBy: { submittedAt: "desc" },
    take: RECENT_GRADES_LIMIT,
    select: {
      multipleChoiceScore: true,
      grade: { select: { essayScore: true } },
      assessment: { select: { maxScore: true } },
    },
  });
  return rows.map((row) => ({
    earned: row.multipleChoiceScore + (row.grade?.essayScore ?? 0),
    maxScore: row.assessment.maxScore,
  }));
}

export function countAiQuestions(parentId: string, studentId: string, now: Date): Promise<number> {
  return db.chatMessage.count({
    where: {
      role: "STUDENT",
      createdAt: { gte: startOfVnWeek(now) },
      thread: { AND: [chatThreadsOfStudent(studentId), { student: childrenOfParent(parentId) }] },
    },
  });
}

export function loadWeekScores(parentId: string, studentId: string) {
  return db.subjectWeekScore.findMany({
    where: { ...ownChild(parentId, studentId), subject: { in: [...CHART_SUBJECTS] } },
    orderBy: { weekStart: "desc" },
    take: CHART_WEEKS * CHART_SUBJECTS.length,
    select: { subject: true, weekStart: true, score: true },
  });
}

export function loadActivity(parentId: string, studentId: string) {
  return db.activityLog.findMany({
    where: { AND: [activityOfParent(parentId), { studentId }] },
    orderBy: [{ occurredAt: "desc" }, { id: "asc" }],
    take: ACTIVITY_LIMIT,
    select: { id: true, kind: true, title: true, description: true, tags: true, occurredAt: true },
  });
}

export function loadLatestNote(parentId: string, studentId: string) {
  return db.parentTeacherNote.findFirst({
    where: { AND: [contactBookOfParent(parentId), { studentId }] },
    orderBy: [{ createdAt: "desc" }, { id: "asc" }],
    select: {
      id: true,
      subject: true,
      weekLabel: true,
      message: true,
      createdAt: true,
      acknowledgedAt: true,
      teacher: { select: { user: { select: { name: true } } } },
    },
  });
}

export function loadUpcoming(parentId: string, studentId: string, now: Date) {
  return db.assessment.findMany({
    where: { AND: [assessmentsOfParent(parentId), upcomingAssessmentsOfStudent(studentId, now)] },
    orderBy: [{ dueAt: "asc" }, { id: "asc" }],
    take: UPCOMING_LIMIT,
    select: {
      id: true,
      kind: true,
      title: true,
      subtitle: true,
      dueAt: true,
      class: { select: { name: true } },
    },
  });
}

export function loadSettings(parentId: string, studentId: string) {
  return db.parentSettings.findUnique({
    where: { parentId_studentId: { parentId, studentId } },
    select: { isNightLimitOn: true, nightLimitStartMin: true, isInstantAlertOn: true },
  });
}

export async function loadDeviceNames(parentId: string, studentId: string): Promise<string[]> {
  const devices = await db.studentDevice.findMany({
    where: ownChild(parentId, studentId),
    orderBy: [{ lastSeenAt: "desc" }, { name: "asc" }],
    take: DEVICES_LIMIT,
    select: { name: true },
  });
  return devices.map((device) => device.name);
}

export async function loadRecentBadgeTitle(
  parentId: string,
  studentId: string,
  now: Date,
): Promise<string | null> {
  const earned = await db.studentBadge.findFirst({
    where: { ...ownChild(parentId, studentId), earnedAt: { gte: daysAgo(now, BADGE_RECENT_DAYS) } },
    orderBy: { earnedAt: "desc" },
    select: { badge: { select: { title: true } } },
  });
  return earned?.badge.title ?? null;
}
