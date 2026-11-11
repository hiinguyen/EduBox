import { hashPassword } from "../../src/lib/auth/password";
import {
  ACADEMIC_YEAR,
  CLASSES,
  DEMO_EMAIL_DOMAIN,
  NAMED_STUDENTS,
  PARENT_ACCOUNTS,
  PARENT_LINKS,
  STUDENT_ACCOUNTS,
  STUDENT_CODES,
  TEACHER_ACCOUNTS,
  TERM_LABEL,
  type SeedAccount,
} from "../seed-data/people";
import { lookup, type SeedContext } from "./context";

const FILLER_PREFIX = "Học sinh";

async function upsertUser(
  db: SeedContext["db"],
  account: SeedAccount,
  role: "STUDENT" | "PARENT" | "TEACHER",
  passwordHash: string,
): Promise<string> {
  const user = await db.user.upsert({
    where: { email: account.email },
    update: { name: account.name, role },
    create: { email: account.email, name: account.name, role },
    select: { id: true },
  });
  await db.credential.upsert({
    where: { userId: user.id },
    update: { passwordHash },
    create: { userId: user.id, passwordHash },
  });
  return user.id;
}

async function seedClasses(db: SeedContext["db"]): Promise<Record<string, string>> {
  const classIds: Record<string, string> = {};

  for (const item of CLASSES) {
    const saved = await db.schoolClass.upsert({
      where: { academicYear_name: { academicYear: ACADEMIC_YEAR, name: item.name } },
      update: {
        trackLabel: item.trackLabel,
        subjectLabel: item.subjectLabel,
        termLabel: TERM_LABEL,
      },
      create: {
        name: item.name,
        trackLabel: item.trackLabel,
        subjectLabel: item.subjectLabel,
        termLabel: TERM_LABEL,
        academicYear: ACADEMIC_YEAR,
      },
      select: { id: true },
    });
    classIds[item.key] = saved.id;
  }
  return classIds;
}

async function seedTeachers(db: SeedContext["db"], classIds: Record<string, string>, hash: string) {
  const teacherIds: Record<string, string> = {};
  const userIds: Record<string, string> = {};

  for (const [key, teacher] of Object.entries(TEACHER_ACCOUNTS)) {
    const userId = await upsertUser(db, teacher, "TEACHER", hash);
    const profile = await db.teacherProfile.upsert({
      where: { userId },
      update: { department: teacher.department, subjectLabel: teacher.subjectLabel },
      create: { userId, department: teacher.department, subjectLabel: teacher.subjectLabel },
      select: { id: true },
    });
    teacherIds[key] = profile.id;
    userIds[`teacher:${key}`] = userId;
  }

  const links = CLASSES.flatMap((item) =>
    item.teacherKeys.map((teacher) => ({
      teacherId: lookup(teacherIds, teacher),
      classId: lookup(classIds, item.key),
    })),
  );
  await db.teacherClass.createMany({ data: links, skipDuplicates: true });
  return { teacherIds, userIds };
}

async function seedLoginStudents(
  db: SeedContext["db"],
  classIds: Record<string, string>,
  hash: string,
) {
  const studentIds: Record<string, string> = {};
  const userIds: Record<string, string> = {};

  for (const [key, account] of Object.entries(STUDENT_ACCOUNTS)) {
    const meta = STUDENT_CODES[account.key];
    const userId = await upsertUser(db, account, "STUDENT", hash);
    const profile = await db.studentProfile.upsert({
      where: { userId },
      update: { studentCode: meta.code },
      create: { userId, studentCode: meta.code },
      select: { id: true },
    });
    studentIds[account.key] = profile.id;
    userIds[`student:${key}`] = userId;
    await db.enrollment.createMany({
      data: [{ classId: lookup(classIds, meta.classKey), studentId: profile.id }],
      skipDuplicates: true,
    });
  }
  return { studentIds, userIds };
}

async function seedParents(
  db: SeedContext["db"],
  studentIds: Record<string, string>,
  hash: string,
) {
  const parentIds: Record<string, string> = {};
  const userIds: Record<string, string> = {};

  for (const account of Object.values(PARENT_ACCOUNTS)) {
    const userId = await upsertUser(db, account, "PARENT", hash);
    const profile = await db.parentProfile.upsert({
      where: { userId },
      update: {},
      create: { userId },
      select: { id: true },
    });
    parentIds[account.key] = profile.id;
    userIds[`parent:${account.key}`] = userId;
  }

  await db.parentChild.createMany({
    data: PARENT_LINKS.map((link) => ({
      parentId: lookup(parentIds, link.parent),
      studentId: lookup(studentIds, link.student),
    })),
    skipDuplicates: true,
  });
  return { parentIds, userIds };
}

/** Students without a login: named ones from the teacher fixtures plus numbered fillers to reach each class size. */
async function seedRosterStudents(
  db: SeedContext["db"],
  classIds: Record<string, string>,
  studentIds: Record<string, string>,
): Promise<void> {
  const named = NAMED_STUDENTS.map((student) => ({ ...student, id: `stu-${student.key}` }));
  const fillers = CLASSES.flatMap((item) => {
    const existing =
      named.filter((student) => student.classKey === item.key).length +
      Object.values(STUDENT_CODES).filter((meta) => meta.classKey === item.key).length;
    return Array.from({ length: item.studentCount - existing }, (_, index) => ({
      id: `stu-${item.key}-${index + 1}`,
      key: `${item.key}-${index + 1}`,
      name: `${FILLER_PREFIX} ${item.name} ${String(index + 1).padStart(2, "0")}`,
      code: `${item.name}-${String(index + 1).padStart(3, "0")}`,
      classKey: item.key,
    }));
  });
  const roster = [...named, ...fillers];

  await db.user.createMany({
    data: roster.map((student) => ({
      id: `usr-${student.id}`,
      email: `${student.id}@${DEMO_EMAIL_DOMAIN}`,
      name: student.name,
      role: "STUDENT" as const,
    })),
    skipDuplicates: true,
  });
  await db.studentProfile.createMany({
    data: roster.map((student) => ({
      id: student.id,
      userId: `usr-${student.id}`,
      studentCode: student.code,
    })),
    skipDuplicates: true,
  });
  await db.enrollment.createMany({
    data: roster.map((student) => ({
      classId: lookup(classIds, student.classKey),
      studentId: student.id,
    })),
    skipDuplicates: true,
  });
  for (const student of roster) {
    studentIds[student.key] = student.id;
  }
}

export async function seedPeople(
  db: SeedContext["db"],
  demoPassword: string,
): Promise<SeedContext> {
  const hash = await hashPassword(demoPassword);
  const classIds = await seedClasses(db);
  const teachers = await seedTeachers(db, classIds, hash);
  const students = await seedLoginStudents(db, classIds, hash);
  const parents = await seedParents(db, students.studentIds, hash);
  const studentIds: Record<string, string> = { ...students.studentIds };

  await seedRosterStudents(db, classIds, studentIds);

  return {
    db,
    studentIds,
    parentIds: parents.parentIds,
    teacherIds: teachers.teacherIds,
    userIds: { ...teachers.userIds, ...students.userIds, ...parents.userIds },
    classIds,
  };
}
