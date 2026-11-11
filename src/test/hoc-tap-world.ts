import type { Role } from "@/generated/prisma/enums";
import type { SessionUser } from "@/lib/auth/session";
import { db } from "@/lib/db";
import { MS_PER_DAY, MS_PER_HOUR } from "@/lib/format/time";
import { createTaggedWorld } from "./world";

const LESSON_SECONDS = 600;
const COURSE_LESSON_COUNT = 10;
const COURSE_LESSONS = 3;

export interface HocTapWorld {
  readonly tag: string;
  readonly studentA: SessionUser;
  readonly studentB: SessionUser;
  readonly parent: SessionUser;
  readonly teacher: SessionUser;
  /** The featured lesson: published to student A's class and number 1 of the course. */
  readonly lessonId: string;
  /** Lessons 2 and 3 of the same course, also visible to student A. */
  readonly courseLessonIds: readonly string[];
  /** Published but not assigned to any class, so no student can see it. */
  readonly otherLessonId: string;
  readonly courseId: string;
  readonly classId: string;
  readonly assessmentTitle: string;
  readonly examAssessmentId: string;
  readonly cleanup: () => Promise<void>;
}

async function sessionUserOf(
  role: Role,
  profile: { readonly id: string; readonly userId: string },
  name: string,
): Promise<SessionUser> {
  const user = await db.user.update({
    where: { id: profile.userId },
    data: { name },
    select: { id: true, email: true },
  });
  return { id: user.id, role, name, email: user.email, profileId: profile.id };
}

async function createCourseLessons(tag: string, teacherId: string, classId: string) {
  const course = await db.course.create({
    data: {
      slug: tag,
      subjectLabel: "Toán test",
      title: `course-${tag}`,
      instructorLabel: "Cô Test",
      durationMinutes: 30,
      lessonCount: COURSE_LESSON_COUNT,
      icon: "science",
      tone: "PRIMARY",
    },
    select: { id: true },
  });
  const createdAt = new Date(Date.now() - MS_PER_DAY);
  const ids: string[] = [];
  for (let number = 2; number <= COURSE_LESSONS; number += 1) {
    const lesson = await db.lesson.create({
      data: {
        authorId: teacherId,
        courseId: course.id,
        number,
        title: `course-lesson-${number}-${tag}`,
        durationSeconds: LESSON_SECONDS,
        status: "PUBLISHED",
        createdAt,
        classes: { create: { classId } },
      },
      select: { id: true },
    });
    ids.push(lesson.id);
  }
  return { courseId: course.id, courseLessonIds: ids };
}

/**
 * Builds on `createTaggedWorld` (family A/B, class, lesson, exam) and adds the learning
 * content this domain needs. Every added row carries the tag, and `cleanup` removes exactly
 * those rows plus the tagged world, never touching other data.
 */
export async function createHocTapWorld(): Promise<HocTapWorld> {
  const { world, tag, cleanup: cleanupTagged } = await createTaggedWorld();
  const [childA, childB, parent, teacher] = await Promise.all([
    db.studentProfile.findUniqueOrThrow({ where: { id: world.childA } }),
    db.studentProfile.findUniqueOrThrow({ where: { id: world.childB } }),
    db.parentProfile.findUniqueOrThrow({ where: { id: world.parentA } }),
    db.teacherProfile.findUniqueOrThrow({ where: { id: world.teacherA } }),
  ]);
  // The shared world leaves both students mid-exam; this domain starts from free students.
  await db.examAttempt.updateMany({
    where: { id: { in: [world.attemptA, world.attemptB] } },
    data: { status: "SUBMITTED", submittedAt: new Date() },
  });

  const lessonId = world.lessonA;
  const { courseId, courseLessonIds } = await createCourseLessons(
    tag,
    world.teacherA,
    world.classA,
  );
  await db.lesson.update({
    where: { id: lessonId },
    data: {
      courseId,
      number: 1,
      durationSeconds: LESSON_SECONDS,
      chapters: {
        create: [
          { slug: "c1", startSeconds: 0, title: "Mở đầu", note: "n", currentNote: "c" },
          { slug: "c2", startSeconds: 300, title: "Trọng tâm", note: "n", currentNote: "c" },
        ],
      },
    },
  });
  await db.courseEnrollment.create({
    data: { courseId, studentId: childA.id, currentLesson: 3, progressPercent: 30 },
  });
  const otherLesson = await db.lesson.create({
    data: {
      authorId: world.teacherA,
      title: `hidden-${tag}`,
      durationSeconds: LESSON_SECONDS,
      status: "PUBLISHED",
    },
    select: { id: true },
  });
  const assessmentTitle = `HW-${tag}`;
  await db.assessment.create({
    data: {
      classId: world.classA,
      creatorId: world.teacherA,
      kind: "QUIZ",
      subject: "MATH",
      title: assessmentTitle,
      status: "PUBLISHED",
      dueAt: new Date(Date.now() + MS_PER_DAY),
    },
  });
  const [studentA, studentB, parentUser, teacherUser] = await Promise.all([
    sessionUserOf("STUDENT", childA, "Nguyễn Minh Anh"),
    sessionUserOf("STUDENT", childB, "Trần Gia Bảo"),
    sessionUserOf("PARENT", parent, "Phụ huynh"),
    sessionUserOf("TEACHER", teacher, "Giáo viên"),
  ]);
  const userIds = [studentA.id, studentB.id, parentUser.id, teacherUser.id];

  return {
    tag,
    studentA,
    studentB,
    parent: parentUser,
    teacher: teacherUser,
    lessonId,
    courseLessonIds,
    otherLessonId: otherLesson.id,
    courseId,
    classId: world.classA,
    assessmentTitle,
    examAssessmentId: world.assessmentA,
    cleanup: async () => {
      await db.rateLimitBucket.deleteMany({
        where: { OR: userIds.map((id) => ({ key: { contains: id } })) },
      });
      await db.material.deleteMany({ where: { title: { contains: tag } } });
      await cleanupTagged();
      await db.course.deleteMany({ where: { id: courseId } });
    },
  };
}

/** An exam attempt that is running right now for the student (ends in an hour by default). */
export async function startExamAttempt(
  world: HocTapWorld,
  studentId: string,
  endsAt: Date = new Date(Date.now() + MS_PER_HOUR),
): Promise<string> {
  await db.examAttempt.deleteMany({
    where: { assessmentId: world.examAssessmentId, studentId },
  });
  const attempt = await db.examAttempt.create({
    data: { assessmentId: world.examAssessmentId, studentId, endsAt },
    select: { id: true },
  });
  return attempt.id;
}
