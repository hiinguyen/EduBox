import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { db } from "@/lib/db";
import { createTaggedWorld, type TestWorld } from "@/test/world";
import {
  assessmentsOfParent,
  assessmentsOfStudent,
  assessmentsOfTeacher,
  canParentViewChild,
  canStudentAccessAssessment,
  canStudentAccessAttempt,
  canStudentAccessLesson,
  canTeacherAccessAssessment,
  canTeacherAccessClass,
  canTeacherAccessStudent,
  canTeacherAccessSubmission,
  childrenOfParent,
  classesOfParent,
  classesOfStudent,
  classesOfTeacher,
  contactBookOfParent,
  lessonsVisibleToStudent,
  studentsOfTeacher,
  submissionsOfParent,
  submissionsOfTeacher,
  upcomingAssessmentsOfStudent,
} from "./access";

let world: TestWorld;
let cleanup: () => Promise<void>;
let tag: string;

beforeAll(async () => {
  ({ world, cleanup, tag } = await createTaggedWorld());
});

afterAll(async () => {
  await cleanup();
  await db.$disconnect();
});

async function ids(rows: Promise<readonly { id: string }[]>): Promise<string[]> {
  return (await rows).map((row) => row.id);
}

describe("parent scoping", () => {
  it("childrenOfParent returns only the parent's own child", async () => {
    const found = await ids(db.studentProfile.findMany({ where: childrenOfParent(world.parentA) }));

    expect(found).toEqual([world.childA]);
  });

  it("canParentViewChild is true for own child and false for another family's child", async () => {
    expect(await canParentViewChild(world.parentA, world.childA)).toBe(true);
    expect(await canParentViewChild(world.parentA, world.childB)).toBe(false);
  });

  it("submissionsOfParent hides submissions of other children", async () => {
    const found = await ids(db.submission.findMany({ where: submissionsOfParent(world.parentA) }));

    expect(found).toEqual([world.submissionA]);
  });

  it("classesOfParent and assessmentsOfParent follow the child's enrolment", async () => {
    const classes = await ids(db.schoolClass.findMany({ where: classesOfParent(world.parentA) }));
    const assessments = await ids(
      db.assessment.findMany({ where: assessmentsOfParent(world.parentA) }),
    );

    expect(classes).toEqual([world.classA]);
    expect(assessments).toEqual([world.assessmentA]);
  });

  it("contactBookOfParent matches only notes about the parent's children", async () => {
    const note = { subject: "s", weekLabel: "w", message: "m" };
    await db.parentTeacherNote.createMany({
      data: [
        { studentId: world.childA, teacherId: world.teacherA, ...note },
        { studentId: world.childB, teacherId: world.teacherB, ...note },
      ],
    });

    const notes = await db.parentTeacherNote.findMany({
      where: contactBookOfParent(world.parentA),
    });

    expect(notes.map((entry) => entry.studentId)).toEqual([world.childA]);
  });
});

describe("teacher scoping", () => {
  it("classesOfTeacher and canTeacherAccessClass allow only the teacher's own class", async () => {
    const found = await ids(db.schoolClass.findMany({ where: classesOfTeacher(world.teacherA) }));

    expect(found).toEqual([world.classA]);
    expect(await canTeacherAccessClass(world.teacherA, world.classA)).toBe(true);
    expect(await canTeacherAccessClass(world.teacherA, world.classB)).toBe(false);
  });

  it("studentsOfTeacher only reaches students enrolled in the teacher's classes", async () => {
    const found = await ids(
      db.studentProfile.findMany({ where: studentsOfTeacher(world.teacherA) }),
    );

    expect(found).toEqual([world.childA]);
    expect(await canTeacherAccessStudent(world.teacherA, world.childB)).toBe(false);
  });

  it("assessment and submission scopes exclude other teachers' classes", async () => {
    const assessments = await ids(
      db.assessment.findMany({ where: assessmentsOfTeacher(world.teacherA) }),
    );
    const submissions = await ids(
      db.submission.findMany({ where: submissionsOfTeacher(world.teacherA) }),
    );

    expect(assessments).toEqual([world.assessmentA]);
    expect(submissions).toEqual([world.submissionA]);
    expect(await canTeacherAccessAssessment(world.teacherA, world.assessmentB)).toBe(false);
    expect(await canTeacherAccessSubmission(world.teacherA, world.submissionB)).toBe(false);
    expect(await canTeacherAccessSubmission(world.teacherA, world.submissionA)).toBe(true);
  });
});

describe("student scoping", () => {
  it("canStudentAccessAttempt is limited to the student's own attempt", async () => {
    expect(await canStudentAccessAttempt(world.childA, world.attemptA)).toBe(true);
    expect(await canStudentAccessAttempt(world.childA, world.attemptB)).toBe(false);
  });

  it("assessments and classes are limited to the student's enrolment", async () => {
    const assessments = await ids(
      db.assessment.findMany({ where: assessmentsOfStudent(world.childA) }),
    );
    const classes = await ids(db.schoolClass.findMany({ where: classesOfStudent(world.childA) }));

    expect(assessments).toEqual([world.assessmentA]);
    expect(classes).toEqual([world.classA]);
    expect(await canStudentAccessAssessment(world.childA, world.assessmentB)).toBe(false);
  });

  it("does not offer a draft assessment to the student", async () => {
    await db.assessment.update({ where: { id: world.assessmentA }, data: { status: "DRAFT" } });
    const isVisible = await canStudentAccessAssessment(world.childA, world.assessmentA);
    await db.assessment.update({ where: { id: world.assessmentA }, data: { status: "PUBLISHED" } });

    expect(isVisible).toBe(false);
  });

  it("shows a published lecture only to students of a class it was published to", async () => {
    const own = await ids(db.lesson.findMany({ where: lessonsVisibleToStudent(world.childA) }));

    expect(own).toEqual([world.lessonA]);
    expect(await canStudentAccessLesson(world.childB, world.lessonA)).toBe(false);
  });
});

describe("upcomingAssessmentsOfStudent", () => {
  const NOW = new Date("2026-06-01T00:00:00.000Z");
  const DAY_MS = 86_400_000;

  function create(
    label: string,
    overrides: {
      classId?: string;
      creatorId?: string;
      dueAt?: Date | null;
      status?: "DRAFT" | "PUBLISHED";
    },
  ) {
    return db.assessment.create({
      data: {
        classId: overrides.classId ?? world.classA,
        creatorId: overrides.creatorId ?? world.teacherA,
        kind: "QUIZ",
        subject: "MATH",
        title: `${label}-${tag}`,
        status: overrides.status ?? "PUBLISHED",
        dueAt: overrides.dueAt === undefined ? new Date(NOW.getTime() + DAY_MS) : overrides.dueAt,
      },
      select: { id: true },
    });
  }

  it("lists unsubmitted published assessments due now or later, soonest first", async () => {
    const later = await create("later", { dueAt: new Date(NOW.getTime() + 3 * DAY_MS) });
    const soon = await create("soon", { dueAt: new Date(NOW.getTime() + DAY_MS) });
    const dueNow = await create("now", { dueAt: NOW });
    await create("past", { dueAt: new Date(NOW.getTime() - DAY_MS) });
    await create("no-due", { dueAt: null });
    await create("draft", { status: "DRAFT" });
    await create("other-class", { classId: world.classB, creatorId: world.teacherB });
    const submitted = await create("submitted", {});
    await db.submission.create({
      data: {
        assessmentId: submitted.id,
        studentId: world.childA,
        code: `#S-${tag}`,
        multipleChoiceScore: 1,
      },
    });

    const found = await db.assessment.findMany({
      where: upcomingAssessmentsOfStudent(world.childA, NOW),
      orderBy: { dueAt: "asc" },
      select: { id: true },
    });

    expect(found.map((row) => row.id)).toEqual([dueNow.id, soon.id, later.id]);
  });
});
