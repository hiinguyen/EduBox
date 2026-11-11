import { db } from "@/lib/db";
import type { SessionUser } from "@/lib/auth/session";
import { createTaggedWorld } from "./world";

const ESSAY_MAX = 4;
const MC_MAX = 6;
const MC_SCORE = 5;
const TEST_EMAIL_DOMAIN = "test.local";

export interface GiaoVienWorld {
  /** Same marker the shared tagged world uses; every row created here carries it. */
  readonly tag: string;
  readonly teacherA: SessionUser;
  readonly teacherB: SessionUser;
  /** The student of class A; their parent is `parentUser`. */
  readonly studentUser: SessionUser;
  readonly parentUser: SessionUser;
  readonly otherParentUserId: string;
  readonly classA: string;
  readonly classB: string;
  readonly assessmentA: string;
  readonly assessmentB: string;
  readonly submissionA: string;
  readonly submissionB: string;
  /** A submission to assessment A by a student who is not enrolled in class A. */
  readonly submissionMismatch: string;
  readonly cleanup: () => Promise<void>;
}

async function loadSessionUser(
  role: SessionUser["role"],
  profile: { readonly userId: string; readonly id: string },
): Promise<SessionUser> {
  const user = await db.user.findUniqueOrThrow({
    where: { id: profile.userId },
    select: { id: true, email: true, name: true },
  });
  return { ...user, role, profileId: profile.id };
}

/** A student with a login-less account, so the world's cleanup removes it by its tagged email. */
async function createTaggedStudent(tag: string, key: string): Promise<string> {
  const email = `${key}.${tag}@${TEST_EMAIL_DOMAIN}`;
  const user = await db.user.create({ data: { email, name: email, role: "STUDENT" } });
  const profile = await db.studentProfile.create({
    data: { userId: user.id, studentCode: `${key}-${tag}` },
  });
  return profile.id;
}

export function createSubmission(assessmentId: string, studentId: string, code: string) {
  return db.submission.create({
    data: { assessmentId, studentId, code, multipleChoiceScore: MC_SCORE },
  });
}

/** A student enrolled in `classId`, for tests that need many submissions. */
export async function createEnrolledStudent(tag: string, key: string, classId: string) {
  const studentId = await createTaggedStudent(tag, key);
  await db.enrollment.create({ data: { classId, studentId } });
  return studentId;
}

/**
 * The shared tagged world (two teachers, classes, parents, one submission each) with the
 * essay scale and a mismatched submission that the grading tests need. All rows carry the
 * world's tag and `cleanup()` removes only them, so it is safe next to other suites.
 */
export async function createGiaoVienWorld(): Promise<GiaoVienWorld> {
  const { world, tag, cleanup } = await createTaggedWorld();
  await db.assessment.update({
    where: { id: world.assessmentA },
    data: { essayPrompt: "Câu 14", multipleChoiceMaxScore: MC_MAX, essayMaxScore: ESSAY_MAX },
  });
  await db.assessment.update({
    where: { id: world.assessmentB },
    data: { essayPrompt: "Câu 14", multipleChoiceMaxScore: MC_MAX, essayMaxScore: ESSAY_MAX },
  });
  const [teacherA, teacherB, student, parent, otherParent] = await Promise.all([
    db.teacherProfile.findUniqueOrThrow({ where: { id: world.teacherA } }),
    db.teacherProfile.findUniqueOrThrow({ where: { id: world.teacherB } }),
    db.studentProfile.findUniqueOrThrow({ where: { id: world.childA } }),
    db.parentProfile.findUniqueOrThrow({ where: { id: world.parentA } }),
    db.parentProfile.findUniqueOrThrow({ where: { id: world.parentB } }),
  ]);
  const stranger = await createTaggedStudent(tag, "stranger");
  const mismatch = await createSubmission(world.assessmentA, stranger, `#X-${tag}`);

  return {
    tag,
    teacherA: await loadSessionUser("TEACHER", teacherA),
    teacherB: await loadSessionUser("TEACHER", teacherB),
    studentUser: await loadSessionUser("STUDENT", student),
    parentUser: await loadSessionUser("PARENT", parent),
    otherParentUserId: otherParent.userId,
    classA: world.classA,
    classB: world.classB,
    assessmentA: world.assessmentA,
    assessmentB: world.assessmentB,
    submissionA: world.submissionA,
    submissionB: world.submissionB,
    submissionMismatch: mismatch.id,
    cleanup,
  };
}
