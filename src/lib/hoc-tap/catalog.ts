import "server-only";
import type { CardTone as DbCardTone, Subject } from "@/generated/prisma/enums";
import { db } from "@/lib/db";
import { COURSE_CARD_LIMIT, MATERIAL_LIMIT } from "./constants";
import { buildMaterialFilters } from "./materials";
import type {
  CardTone,
  CourseCard,
  MaterialFilter,
  MaterialFilterOption,
  StudyMaterial,
  SubjectKey,
} from "./types";

const TONES: Readonly<Record<DbCardTone, CardTone>> = {
  PRIMARY: "primary",
  SECONDARY: "secondary",
  TERTIARY: "tertiary",
};

const SUBJECTS: Readonly<Record<Subject, SubjectKey>> = {
  MATH: "math",
  PHYSICS: "physics",
  CHEMISTRY: "chemistry",
  ENGLISH: "english",
};

const DB_SUBJECTS: Readonly<Record<SubjectKey, Subject>> = {
  math: "MATH",
  physics: "PHYSICS",
  chemistry: "CHEMISTRY",
  english: "ENGLISH",
};

export interface CoursesResult {
  readonly courses: readonly CourseCard[];
  readonly total: number;
}

export async function loadCourses(studentId: string): Promise<CoursesResult> {
  const [rows, total] = await Promise.all([
    db.courseEnrollment.findMany({
      where: { studentId },
      orderBy: { updatedAt: "desc" },
      take: COURSE_CARD_LIMIT,
      select: {
        currentLesson: true,
        progressPercent: true,
        course: {
          select: {
            id: true,
            subjectLabel: true,
            title: true,
            instructorLabel: true,
            durationMinutes: true,
            lessonCount: true,
            icon: true,
            tone: true,
          },
        },
      },
    }),
    db.courseEnrollment.count({ where: { studentId } }),
  ]);

  const courses = rows.map(({ course, currentLesson, progressPercent }) => ({
    id: course.id,
    subject: course.subjectLabel,
    title: course.title,
    instructor: `${course.instructorLabel} · Bài ${currentLesson}/${course.lessonCount}`,
    durationMinutes: course.durationMinutes,
    progressPercent,
    icon: course.icon,
    tone: TONES[course.tone],
  }));
  return { courses, total };
}

export interface MaterialsResult {
  readonly materials: readonly StudyMaterial[];
  readonly filters: readonly MaterialFilterOption[];
}

/**
 * Filters by subject in the database so the chips (from a groupBy over every material) never
 * depend on which rows fit in the bounded list.
 */
export async function loadMaterials(filter: MaterialFilter): Promise<MaterialsResult> {
  const [groups, rows] = await Promise.all([
    db.material.groupBy({ by: ["subject"] }),
    db.material.findMany({
      where: filter === "all" ? {} : { subject: DB_SUBJECTS[filter] },
      orderBy: [{ isRecommended: "desc" }, { createdAt: "desc" }],
      take: MATERIAL_LIMIT,
      select: {
        id: true,
        subject: true,
        kind: true,
        title: true,
        detail: true,
        icon: true,
        tone: true,
        footnote: true,
        isRecommended: true,
      },
    }),
  ]);
  const materials = rows.map((row) => ({
    ...row,
    tone: TONES[row.tone],
    subject: SUBJECTS[row.subject],
  }));
  const present = groups.map((group) => SUBJECTS[group.subject]);
  return { materials, filters: buildMaterialFilters(present) };
}
