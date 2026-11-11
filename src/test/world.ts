import { randomBytes } from "node:crypto";
import { hashPassword } from "@/lib/auth/password";
import { db } from "@/lib/db";

export const TEST_PASSWORD = "Test@12345";

const ONE_HOUR_MS = 60 * 60 * 1000;

export interface TestWorld {
  readonly parentA: string;
  readonly parentB: string;
  readonly childA: string;
  readonly childB: string;
  readonly teacherA: string;
  readonly teacherB: string;
  readonly classA: string;
  readonly classB: string;
  readonly assessmentA: string;
  readonly assessmentB: string;
  readonly attemptA: string;
  readonly attemptB: string;
  readonly submissionA: string;
  readonly submissionB: string;
  readonly lessonA: string;
  readonly studentAEmail: string;
}

const TAG_BYTES = 5;
const TEST_EMAIL_DOMAIN = "test.local";

/** Fresh random tag so concurrent or leftover data never collides with a new world. */
function newTag(): string {
  return randomBytes(TAG_BYTES).toString("hex");
}

const RESET_TABLES = ["User", "SchoolClass", "Assessment", "Lesson", "RateLimitBucket"] as const;

/**
 * Empties the tables the integration tests touch (everything else cascades from these).
 *
 * Destructive: it wipes every row in those tables, so it is only safe because integration
 * tests run against the dedicated `<db>_test` database, and only for suites that explicitly
 * need an empty database. It requires `fileParallelism: false` (set in
 * vitest.integration.config.ts) because it would delete rows another test file is using.
 * Prefer `createTaggedWorld()`, which removes only what it created.
 */
export async function resetDatabase(): Promise<void> {
  const list = RESET_TABLES.map((table) => `"${table}"`).join(", ");
  await db.$executeRawUnsafe(`TRUNCATE ${list} RESTART IDENTITY CASCADE`);
}

type RoleName = "STUDENT" | "PARENT" | "TEACHER";

function createUser(email: string, role: RoleName, passwordHash: string) {
  return db.user.create({
    data: { email, name: email, role, credential: { create: { passwordHash } } },
    select: { id: true },
  });
}

function createClass(name: string, tag: string) {
  return db.schoolClass.create({
    data: {
      name: `${name}-${tag}`,
      trackLabel: name,
      subjectLabel: name,
      termLabel: name,
      academicYear: "T",
    },
  });
}

function createAssessment(classId: string, creatorId: string, title: string) {
  return db.assessment.create({
    data: { classId, creatorId, kind: "QUIZ", subject: "MATH", title, status: "PUBLISHED" },
  });
}

function createAttempt(assessmentId: string, studentId: string) {
  return db.examAttempt.create({
    data: { assessmentId, studentId, endsAt: new Date(Date.now() + ONE_HOUR_MS) },
  });
}

function createSubmission(assessmentId: string, studentId: string, code: string) {
  return db.submission.create({
    data: { assessmentId, studentId, code, multipleChoiceScore: 5 },
  });
}

export interface TaggedWorld {
  readonly world: TestWorld;
  /** Unique marker embedded in every created email, code, class name and title. */
  readonly tag: string;
  /** Deletes exactly the rows this world created. Safe to call while other suites run. */
  readonly cleanup: () => Promise<void>;
}

async function deleteTagged(tag: string): Promise<void> {
  const users = await db.user.findMany({
    where: { email: { endsWith: `.${tag}@${TEST_EMAIL_DOMAIN}` } },
    select: { id: true },
  });
  const userIds = users.map((user) => user.id);

  // Restrict relations (assessment creator, lesson author, notes) go before their owners.
  await db.assessment.deleteMany({ where: { title: { endsWith: `-${tag}` } } });
  await db.lesson.deleteMany({ where: { title: { endsWith: `-${tag}` } } });
  await db.parentTeacherNote.deleteMany({
    where: { teacher: { userId: { in: userIds } } },
  });
  await db.schoolClass.deleteMany({ where: { name: { endsWith: `-${tag}` } } });
  await db.user.deleteMany({ where: { id: { in: userIds } } });
}

/**
 * Two independent families, teachers and classes, all tagged with a unique suffix. Suffix A
 * belongs to world A and B to world B, so a test can assert that A never reaches B. Nothing
 * else in the database is touched, so this is safe next to the shared dev data and next to
 * other suites; call `cleanup()` in `afterAll`.
 */
export async function createTaggedWorld(): Promise<TaggedWorld> {
  const tag = newTag();
  const world = await buildWorld(tag);
  return { world, tag, cleanup: () => deleteTagged(tag) };
}

async function buildWorld(tag: string): Promise<TestWorld> {
  const hash = await hashPassword(TEST_PASSWORD);
  const email = (name: string) => `${name}.${tag}@${TEST_EMAIL_DOMAIN}`;
  const studentAEmail = email("student.a");
  const users = {
    parentA: await createUser(email("parent.a"), "PARENT", hash),
    parentB: await createUser(email("parent.b"), "PARENT", hash),
    childA: await createUser(studentAEmail, "STUDENT", hash),
    childB: await createUser(email("student.b"), "STUDENT", hash),
    teacherA: await createUser(email("teacher.a"), "TEACHER", hash),
    teacherB: await createUser(email("teacher.b"), "TEACHER", hash),
  };
  const parentA = await db.parentProfile.create({ data: { userId: users.parentA.id } });
  const parentB = await db.parentProfile.create({ data: { userId: users.parentB.id } });
  const childA = await db.studentProfile.create({
    data: { userId: users.childA.id, studentCode: `T-A-${tag}` },
  });
  const childB = await db.studentProfile.create({
    data: { userId: users.childB.id, studentCode: `T-B-${tag}` },
  });
  const teacherA = await db.teacherProfile.create({
    data: { userId: users.teacherA.id, department: "A", subjectLabel: "A" },
  });
  const teacherB = await db.teacherProfile.create({
    data: { userId: users.teacherB.id, department: "B", subjectLabel: "B" },
  });
  const classA = await createClass("A", tag);
  const classB = await createClass("B", tag);

  await db.parentChild.createMany({
    data: [
      { parentId: parentA.id, studentId: childA.id },
      { parentId: parentB.id, studentId: childB.id },
    ],
  });
  await db.teacherClass.createMany({
    data: [
      { teacherId: teacherA.id, classId: classA.id },
      { teacherId: teacherB.id, classId: classB.id },
    ],
  });
  await db.enrollment.createMany({
    data: [
      { classId: classA.id, studentId: childA.id },
      { classId: classB.id, studentId: childB.id },
    ],
  });

  const assessmentA = await createAssessment(classA.id, teacherA.id, `A-${tag}`);
  const assessmentB = await createAssessment(classB.id, teacherB.id, `B-${tag}`);
  const attemptA = await createAttempt(assessmentA.id, childA.id);
  const attemptB = await createAttempt(assessmentB.id, childB.id);
  const submissionA = await createSubmission(assessmentA.id, childA.id, `#A-${tag}`);
  const submissionB = await createSubmission(assessmentB.id, childB.id, `#B-${tag}`);
  const lessonA = await db.lesson.create({
    data: {
      authorId: teacherA.id,
      title: `A-${tag}`,
      durationSeconds: 60,
      status: "PUBLISHED",
      classes: { create: { classId: classA.id } },
    },
  });

  return {
    parentA: parentA.id,
    parentB: parentB.id,
    childA: childA.id,
    childB: childB.id,
    teacherA: teacherA.id,
    teacherB: teacherB.id,
    classA: classA.id,
    classB: classB.id,
    assessmentA: assessmentA.id,
    assessmentB: assessmentB.id,
    attemptA: attemptA.id,
    attemptB: attemptB.id,
    submissionA: submissionA.id,
    submissionB: submissionB.id,
    lessonA: lessonA.id,
    studentAEmail,
  };
}
