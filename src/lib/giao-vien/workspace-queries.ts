import "server-only";
import type { Prisma } from "@/generated/prisma/client";
import {
  assessmentsOfTeacher,
  classesOfTeacher,
  lessonsOfTeacher,
  studentsOfTeacher,
  submissionsOfTeacher,
} from "@/lib/auth/access";
import { db } from "@/lib/db";
import { LECTURES_PAGE_SIZE, MAX_CLASSES, MAX_CLASSES_PER_LECTURE, MAX_GAPS } from "./constants";
import { formatDeadline } from "./labels";
import { paginate } from "./pagination";
import { combineAverages, computeCompletionRate } from "./stats";
import type { ClassOption, KnowledgeInsights, LectureLibraryData, TeacherStats } from "./types";
import { toInsights, toLecture } from "./view-models";

export interface ClassRecord extends ClassOption {
  readonly termLabel: string;
}

export function loadClasses(teacherId: string): Promise<ClassRecord[]> {
  return db.schoolClass.findMany({
    where: classesOfTeacher(teacherId),
    orderBy: [{ name: "asc" }, { id: "asc" }],
    take: MAX_CLASSES,
    select: { id: true, name: true, trackLabel: true, subjectLabel: true, termLabel: true },
  });
}

export function loadTeacherRecord(teacherId: string) {
  return db.teacherProfile.findUnique({
    where: { id: teacherId },
    select: { department: true, subjectLabel: true, user: { select: { name: true } } },
  });
}

export async function loadLectures(
  teacherId: string,
  requestedPage: number | undefined,
): Promise<LectureLibraryData> {
  const scope = lessonsOfTeacher(teacherId);
  const [total, approved] = await Promise.all([
    db.lesson.count({ where: scope }),
    db.lesson.count({ where: { AND: [scope, { status: "PUBLISHED" }] } }),
  ]);
  const pagination = paginate(total, requestedPage ?? 1, LECTURES_PAGE_SIZE);
  const lessons = await db.lesson.findMany({
    where: scope,
    orderBy: [{ updatedAt: "desc" }, { id: "asc" }],
    skip: pagination.skip,
    take: LECTURES_PAGE_SIZE,
    select: {
      id: true,
      title: true,
      subtitle: true,
      topic: true,
      durationSeconds: true,
      viewCount: true,
      ratingAverage: true,
      ratingCount: true,
      status: true,
      classes: {
        where: { class: classesOfTeacher(teacherId) },
        orderBy: { class: { name: "asc" } },
        take: MAX_CLASSES_PER_LECTURE,
        select: { class: { select: { name: true } } },
      },
    },
  });
  return { items: lessons.map(toLecture), pagination, total, approved };
}

export async function loadInsights(teacherId: string): Promise<KnowledgeInsights | null> {
  const insight = await db.teacherInsight.findUnique({
    where: { teacherId },
    select: {
      scannedSubmissions: true,
      remediationIntro: true,
      remediationLecture: true,
      remediationOutro: true,
      gaps: {
        orderBy: { position: "asc" },
        take: MAX_GAPS,
        select: { id: true, topic: true, percent: true, tone: true, note: true },
      },
    },
  });
  return insight ? toInsights(insight) : null;
}

/** Counts in SQL so the rate covers every assessment of the teacher, never an arbitrary subset. */
async function loadCompletion(teacherId: string) {
  const published: Prisma.AssessmentWhereInput = {
    AND: [assessmentsOfTeacher(teacherId), { status: { not: "DRAFT" } }],
  };
  const [submitted, assessmentsPerClass] = await Promise.all([
    db.submission.count({ where: { assessment: published } }),
    db.assessment.groupBy({ by: ["classId"], where: published, _count: { _all: true } }),
  ]);
  const enrolledPerClass = await db.enrollment.groupBy({
    by: ["classId"],
    where: { classId: { in: assessmentsPerClass.map((item) => item.classId) } },
    _count: { _all: true },
  });
  const enrolledByClass = new Map(enrolledPerClass.map((item) => [item.classId, item._count._all]));
  const expected = assessmentsPerClass.reduce(
    (sum, item) => sum + item._count._all * (enrolledByClass.get(item.classId) ?? 0),
    0,
  );
  return computeCompletionRate(submitted, expected);
}

async function loadAverage(teacherId: string) {
  const latest = await db.assessment.findFirst({
    where: {
      AND: [assessmentsOfTeacher(teacherId), { submissions: { some: { grade: { isNot: null } } } }],
    },
    orderBy: [{ createdAt: "desc" }, { id: "desc" }],
    select: { id: true, title: true },
  });
  if (!latest) return null;

  const graded: Prisma.SubmissionWhereInput = {
    AND: [submissionsOfTeacher(teacherId), { assessmentId: latest.id, grade: { isNot: null } }],
  };
  const [multipleChoice, essay] = await Promise.all([
    db.submission.aggregate({ where: graded, _avg: { multipleChoiceScore: true } }),
    db.grade.aggregate({ where: { submission: graded }, _avg: { essayScore: true } }),
  ]);
  const score = combineAverages(multipleChoice._avg.multipleChoiceScore, essay._avg.essayScore);
  return score === null ? null : { score, sourceTitle: latest.title };
}

async function loadDeadline(teacherId: string, now: Date): Promise<string | null> {
  const next = await db.assessment.findFirst({
    where: {
      AND: [
        assessmentsOfTeacher(teacherId),
        { gradingDueAt: { not: null }, submissions: { some: { grade: null } } },
      ],
    },
    orderBy: { gradingDueAt: "asc" },
    select: { gradingDueAt: true },
  });
  return next?.gradingDueAt ? formatDeadline(next.gradingDueAt, now) : null;
}

export async function loadStats(
  teacherId: string,
  classNames: readonly string[],
  now: Date,
): Promise<TeacherStats> {
  const [totalStudents, pendingSubmissions, gradingDeadlineLabel, completion, average] =
    await Promise.all([
      db.studentProfile.count({ where: studentsOfTeacher(teacherId) }),
      db.submission.count({ where: { AND: [submissionsOfTeacher(teacherId), { grade: null }] } }),
      loadDeadline(teacherId, now),
      loadCompletion(teacherId),
      loadAverage(teacherId),
    ]);
  return {
    totalStudents,
    classNames,
    pendingSubmissions,
    gradingDeadlineLabel,
    completion,
    average,
  };
}
