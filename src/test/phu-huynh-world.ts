import { db } from "@/lib/db";
import { getVnCalendarDay } from "@/lib/format/date";
import { MS_PER_DAY, MS_PER_HOUR } from "@/lib/format/time";
import { createTaggedWorld, type TaggedWorld } from "./world";

const TEST_EMAIL_DOMAIN = "test.local";
const SEEDED_STUDY_SECONDS = 7_200;
const SEEDED_MATH_SCORE = 8.5;
const SEEDED_ESSAY_SCORE = 2;
const SEEDED_NOTE_WEEK = "Tuần 1";

export interface PhuHuynhWorld extends TaggedWorld {
  /** User ids (not profile ids) of the session owners, for mocking the signed-in user. */
  readonly users: {
    readonly parentA: string;
    readonly parentB: string;
    readonly studentA: string;
    readonly teacherA: string;
    /** A parent with no linked child. */
    readonly parentWithoutChildren: string;
  };
  /** ParentProfile id of the parent with no linked child. */
  readonly parentWithoutChildren: string;
  readonly noteA: string;
  readonly noteB: string;
  /** A published assessment due in 12 hours in each family's class. */
  readonly dueAssessmentA: string;
  readonly dueAssessmentB: string;
  readonly badgeId: string;
}

async function userIdOfParent(profileId: string): Promise<string> {
  const profile = await db.parentProfile.findUniqueOrThrow({
    where: { id: profileId },
    select: { userId: true },
  });
  return profile.userId;
}

async function userIdOfStudent(profileId: string): Promise<string> {
  const profile = await db.studentProfile.findUniqueOrThrow({
    where: { id: profileId },
    select: { userId: true },
  });
  return profile.userId;
}

async function userIdOfTeacher(profileId: string): Promise<string> {
  const profile = await db.teacherProfile.findUniqueOrThrow({
    where: { id: profileId },
    select: { userId: true },
  });
  return profile.userId;
}

function createNote(studentId: string, teacherId: string, label: string) {
  return db.parentTeacherNote.create({
    data: {
      studentId,
      teacherId,
      subject: "Toán học",
      weekLabel: SEEDED_NOTE_WEEK,
      message: `Nhận xét ${label}`,
    },
    select: { id: true },
  });
}

function createDueAssessment(classId: string, teacherId: string, label: string, tag: string) {
  return db.assessment.create({
    data: {
      classId,
      creatorId: teacherId,
      kind: "HOMEWORK",
      subject: "MATH",
      title: `Due-${label}-${tag}`,
      status: "PUBLISHED",
      dueAt: new Date(Date.now() + MS_PER_HOUR * 12),
    },
    select: { id: true },
  });
}

async function createParentWithoutChildren(tag: string) {
  const user = await db.user.create({
    data: {
      email: `parent.c.${tag}@${TEST_EMAIL_DOMAIN}`,
      name: "Phụ huynh chưa liên kết",
      role: "PARENT",
    },
    select: { id: true },
  });
  const profile = await db.parentProfile.create({
    data: { userId: user.id },
    select: { id: true },
  });
  return { userId: user.id, profileId: profile.id };
}

/**
 * Two tagged families (see createTaggedWorld) plus what the parent portal reads: a contact
 * book note and a due assessment per family, a badge, and a parent without children.
 * Nothing outside the tag is touched and `cleanup()` removes only what was created.
 */
export async function createPhuHuynhWorld(): Promise<PhuHuynhWorld> {
  const base = await createTaggedWorld();
  const { world, tag } = base;
  const [noteA, noteB, dueA, dueB, lonely, badge] = await Promise.all([
    createNote(world.childA, world.teacherA, "A"),
    createNote(world.childB, world.teacherB, "B"),
    createDueAssessment(world.classA, world.teacherA, "A", tag),
    createDueAssessment(world.classB, world.teacherB, "B", tag),
    createParentWithoutChildren(tag),
    db.badge.create({
      data: {
        code: `B-${tag}`,
        title: `Huy hiệu ${tag}`,
        description: "Thử nghiệm",
        weeklyMinutesToEarn: 60,
      },
      select: { id: true },
    }),
  ]);
  const users = {
    parentA: await userIdOfParent(world.parentA),
    parentB: await userIdOfParent(world.parentB),
    studentA: await userIdOfStudent(world.childA),
    teacherA: await userIdOfTeacher(world.teacherA),
    parentWithoutChildren: lonely.userId,
  };

  const cleanup = async () => {
    const userIds = Object.values(users);
    await db.rateLimitBucket.deleteMany({
      where: { OR: userIds.map((id) => ({ key: { endsWith: id } })) },
    });
    await db.badge.deleteMany({ where: { id: badge.id } });
    await db.user.deleteMany({ where: { id: lonely.userId } });
    await base.cleanup();
  };

  return {
    ...base,
    cleanup,
    users,
    parentWithoutChildren: lonely.profileId,
    noteA: noteA.id,
    noteB: noteB.id,
    dueAssessmentA: dueA.id,
    dueAssessmentB: dueB.id,
    badgeId: badge.id,
  };
}

export interface SeededChildData {
  readonly studiedSeconds: number;
  readonly mathScore: number;
  /** Multiple choice plus essay score of the graded submission. */
  readonly gradedEarned: number;
}

/** Study time, activity, chart score, AI question, grade, device and badge for one child. */
export async function seedChildData(
  world: PhuHuynhWorld,
  studentId: string,
  submissionId: string,
  teacherId: string,
): Promise<SeededChildData> {
  const today = new Date(`${getVnCalendarDay(new Date())}T00:00:00.000Z`);
  await db.studyDay.create({
    data: { studentId, day: today, studiedSeconds: SEEDED_STUDY_SECONDS },
  });
  await db.activityLog.create({
    data: {
      studentId,
      kind: "EXAM_COMPLETED",
      title: "Hoàn thành bài thi",
      description: [{ text: "Đạt 8 điểm" }],
      tags: [{ label: "Đã chấm", tone: "neutral" }],
      occurredAt: new Date(),
    },
  });
  await db.subjectWeekScore.create({
    data: { studentId, subject: "MATH", weekStart: today, score: SEEDED_MATH_SCORE },
  });
  const thread = await db.chatThread.create({ data: { studentId } });
  await db.chatMessage.create({ data: { threadId: thread.id, role: "STUDENT", text: "Hỏi" } });
  await db.studentDevice.create({ data: { studentId, name: `Máy ${world.tag}` } });
  await db.studentBadge.create({ data: { studentId, badgeId: world.badgeId } });
  await db.grade.create({
    data: { submissionId, gradedById: teacherId, essayScore: SEEDED_ESSAY_SCORE },
  });
  const submission = await db.submission.findUniqueOrThrow({
    where: { id: submissionId },
    select: { multipleChoiceScore: true },
  });
  return {
    studiedSeconds: SEEDED_STUDY_SECONDS,
    mathScore: SEEDED_MATH_SCORE,
    gradedEarned: submission.multipleChoiceScore + SEEDED_ESSAY_SCORE,
  };
}

/** A study day `daysFromToday` Vietnam days away from today (negative is the past). */
export function studyDayFromToday(daysFromToday: number): Date {
  const today = new Date(`${getVnCalendarDay(new Date())}T00:00:00.000Z`);
  return new Date(today.getTime() + daysFromToday * MS_PER_DAY);
}
