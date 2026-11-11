import "server-only";
import type { Prisma } from "@/generated/prisma/client";
import { db } from "@/lib/db";

/**
 * Ownership scoping as Prisma `where` fragments.
 *
 * Every domain query for a protected model must AND one of these fragments into its
 * `where`, so a forgotten filter is a code-review failure rather than a data leak:
 *
 *   db.submission.findMany({ where: { AND: [submissionsOfTeacher(teacherId), { ... }] }, take })
 *
 * All parameters are profile ids (SessionUser.profileId), not user ids.
 */

// --- Students and classes ---------------------------------------------------

/** Students a parent may see: their own children only. */
export function childrenOfParent(parentId: string): Prisma.StudentProfileWhereInput {
  return { parents: { some: { parentId } } };
}

/** Students a teacher may see: those enrolled in one of the teacher's classes. */
export function studentsOfTeacher(teacherId: string): Prisma.StudentProfileWhereInput {
  return { enrollments: { some: { class: { teachers: { some: { teacherId } } } } } };
}

/** Classes a teacher owns. */
export function classesOfTeacher(teacherId: string): Prisma.SchoolClassWhereInput {
  return { teachers: { some: { teacherId } } };
}

/** Classes a student is enrolled in. */
export function classesOfStudent(studentId: string): Prisma.SchoolClassWhereInput {
  return { enrollments: { some: { studentId } } };
}

/** Classes that contain at least one of the parent's children. */
export function classesOfParent(parentId: string): Prisma.SchoolClassWhereInput {
  return { enrollments: { some: { student: childrenOfParent(parentId) } } };
}

// --- Learning content -------------------------------------------------------

/** Lectures a teacher authored. */
export function lessonsOfTeacher(teacherId: string): Prisma.LessonWhereInput {
  return { authorId: teacherId };
}

/** Published lectures visible to a student through their classes. */
export function lessonsVisibleToStudent(studentId: string): Prisma.LessonWhereInput {
  return { status: "PUBLISHED", classes: { some: { class: classesOfStudent(studentId) } } };
}

export function chatThreadsOfStudent(studentId: string): Prisma.ChatThreadWhereInput {
  return { studentId };
}

export function notesOfStudent(studentId: string): Prisma.NoteWhereInput {
  return { studentId };
}

// --- Assessments, attempts, grading ----------------------------------------

/** Assessments of the teacher's classes. */
export function assessmentsOfTeacher(teacherId: string): Prisma.AssessmentWhereInput {
  return { class: classesOfTeacher(teacherId) };
}

/** Published assessments a student may open. */
export function assessmentsOfStudent(studentId: string): Prisma.AssessmentWhereInput {
  return { status: "PUBLISHED", class: classesOfStudent(studentId) };
}

/**
 * Published assessments a student still has to do: due now or later and not yet submitted
 * by that student. Order by `dueAt` ascending at the call site.
 */
export function upcomingAssessmentsOfStudent(
  studentId: string,
  now: Date,
): Prisma.AssessmentWhereInput {
  return {
    AND: [
      assessmentsOfStudent(studentId),
      { dueAt: { gte: now } },
      { submissions: { none: { studentId } } },
    ],
  };
}

/** Published assessments of the classes a parent's children attend. */
export function assessmentsOfParent(parentId: string): Prisma.AssessmentWhereInput {
  return { status: "PUBLISHED", class: classesOfParent(parentId) };
}

export function attemptsOfStudent(studentId: string): Prisma.ExamAttemptWhereInput {
  return { studentId };
}

export function submissionsOfStudent(studentId: string): Prisma.SubmissionWhereInput {
  return { studentId };
}

/** Submissions to assessments of the teacher's classes. */
export function submissionsOfTeacher(teacherId: string): Prisma.SubmissionWhereInput {
  return { assessment: assessmentsOfTeacher(teacherId) };
}

export function submissionsOfParent(parentId: string): Prisma.SubmissionWhereInput {
  return { student: childrenOfParent(parentId) };
}

// --- Parent portal ----------------------------------------------------------

export function activityOfParent(parentId: string): Prisma.ActivityLogWhereInput {
  return { student: childrenOfParent(parentId) };
}

/** Contact book entries about a parent's children. */
export function contactBookOfParent(parentId: string): Prisma.ParentTeacherNoteWhereInput {
  return { student: childrenOfParent(parentId) };
}

/** Contact book entries a teacher wrote. */
export function contactBookOfTeacher(teacherId: string): Prisma.ParentTeacherNoteWhereInput {
  return { teacherId };
}

export function notificationsOfUser(userId: string): Prisma.NotificationWhereInput {
  return { userId };
}

// --- Boolean checks (use for single-resource guards) -----------------------

async function exists(count: Promise<number>): Promise<boolean> {
  return (await count) > 0;
}

export function canParentViewChild(parentId: string, studentId: string): Promise<boolean> {
  return exists(
    db.studentProfile.count({ where: { AND: [{ id: studentId }, childrenOfParent(parentId)] } }),
  );
}

export function canTeacherAccessClass(teacherId: string, classId: string): Promise<boolean> {
  return exists(
    db.schoolClass.count({ where: { AND: [{ id: classId }, classesOfTeacher(teacherId)] } }),
  );
}

export function canTeacherAccessStudent(teacherId: string, studentId: string): Promise<boolean> {
  return exists(
    db.studentProfile.count({ where: { AND: [{ id: studentId }, studentsOfTeacher(teacherId)] } }),
  );
}

export function canTeacherAccessAssessment(
  teacherId: string,
  assessmentId: string,
): Promise<boolean> {
  return exists(
    db.assessment.count({
      where: { AND: [{ id: assessmentId }, assessmentsOfTeacher(teacherId)] },
    }),
  );
}

export function canTeacherAccessSubmission(
  teacherId: string,
  submissionId: string,
): Promise<boolean> {
  return exists(
    db.submission.count({
      where: { AND: [{ id: submissionId }, submissionsOfTeacher(teacherId)] },
    }),
  );
}

export function canStudentAccessAssessment(
  studentId: string,
  assessmentId: string,
): Promise<boolean> {
  return exists(
    db.assessment.count({
      where: { AND: [{ id: assessmentId }, assessmentsOfStudent(studentId)] },
    }),
  );
}

export function canStudentAccessAttempt(studentId: string, attemptId: string): Promise<boolean> {
  return exists(
    db.examAttempt.count({ where: { AND: [{ id: attemptId }, attemptsOfStudent(studentId)] } }),
  );
}

export function canStudentAccessLesson(studentId: string, lessonId: string): Promise<boolean> {
  return exists(
    db.lesson.count({ where: { AND: [{ id: lessonId }, lessonsVisibleToStudent(studentId)] } }),
  );
}
