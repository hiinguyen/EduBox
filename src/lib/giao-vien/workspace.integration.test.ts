import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { db } from "@/lib/db";
import { LECTURES_PAGE_SIZE, MAX_ASSESSMENTS, SUBMISSIONS_PAGE_SIZE } from "./constants";
import {
  createEnrolledStudent,
  createGiaoVienWorld,
  createSubmission,
  type GiaoVienWorld,
} from "@/test/giao-vien-world";
import { findDefaultFocusTarget, getTeacherWorkspace } from "./workspace";

let world: GiaoVienWorld;

beforeAll(async () => {
  world = await createGiaoVienWorld();
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

describe("getTeacherWorkspace scoping", () => {
  it("shows the teacher's own class, assessment and pending submissions", async () => {
    const workspace = await getTeacherWorkspace(world.teacherA, {});

    expect(workspace?.grading?.selection).toEqual({
      classId: world.classA,
      assessmentId: world.assessmentA,
    });
    expect(workspace?.grading?.rows.map((row) => row.id).sort()).toEqual(
      [world.submissionA, world.submissionMismatch].sort(),
    );
    expect(workspace?.stats.pendingSubmissions).toBe(2);
    expect(workspace?.stats.totalStudents).toBe(1);
  });

  it("falls back to the own class when the URL names another teacher's class or assessment", async () => {
    const workspace = await getTeacherWorkspace(world.teacherA, {
      classId: world.classB,
      assessmentId: world.assessmentB,
    });

    expect(workspace?.grading?.selection.classId).toBe(world.classA);
    expect(workspace?.grading?.selection.assessmentId).toBe(world.assessmentA);
    expect(JSON.stringify(workspace)).not.toContain(world.submissionB);
  });

  it("returns null for another teacher's submission and for a missing one alike", async () => {
    const foreign = await getTeacherWorkspace(world.teacherA, { submissionId: world.submissionB });
    const missing = await getTeacherWorkspace(world.teacherA, { submissionId: "no-such-id" });

    expect(foreign).toBeNull();
    expect(missing).toBeNull();
  });

  it("opens an owned submission from the URL", async () => {
    const workspace = await getTeacherWorkspace(world.teacherA, {
      submissionId: world.submissionA,
    });

    expect(workspace?.grading?.selected?.id).toBe(world.submissionA);
  });

  it("never exposes ownership fields in the view models", async () => {
    const workspace = await getTeacherWorkspace(world.teacherA, {});
    const json = JSON.stringify(workspace);

    expect(json).not.toContain(world.teacherA.profileId);
    expect(json).not.toContain(world.studentUser.profileId);
    expect(json).not.toContain("teacherId");
  });

  it("gives teacher B only their own data", async () => {
    const workspace = await getTeacherWorkspace(world.teacherB, {});

    expect(workspace?.grading?.rows.map((row) => row.id)).toEqual([world.submissionB]);
    expect(workspace?.stats.pendingSubmissions).toBe(1);
  });
});

describe("pending count follows grades", () => {
  it("drops by one once a submission has a Grade row", async () => {
    await db.grade.create({
      data: {
        submissionId: world.submissionA,
        gradedById: world.teacherA.profileId,
        essayScore: 3,
      },
    });

    const workspace = await getTeacherWorkspace(world.teacherA, {});
    await db.grade.delete({ where: { submissionId: world.submissionA } });

    expect(workspace?.stats.pendingSubmissions).toBe(1);
    expect(workspace?.grading?.pendingCount).toBe(1);
    expect(workspace?.stats.average?.score).toBeCloseTo(8);
  });
});

describe("default focus (single redirect)", () => {
  it("picks the first pending submission without loading the workspace", async () => {
    const target = await findDefaultFocusTarget(world.teacherA, {});
    const workspace = await getTeacherWorkspace(world.teacherA, {});

    expect(target).toEqual({
      classId: world.classA,
      assessmentId: world.assessmentA,
      submissionId: workspace?.grading?.selected?.id,
    });
  });

  it("answers null once the URL pins a submission, so the redirect cannot loop", async () => {
    const target = await findDefaultFocusTarget(world.teacherA, {
      submissionId: world.submissionA,
    });

    expect(target).toBeNull();
  });

  it("opens the same submission when the pinned URL is loaded", async () => {
    const target = await findDefaultFocusTarget(world.teacherA, {});
    const pinned = await getTeacherWorkspace(world.teacherA, { ...target });

    expect(pinned?.grading?.selected?.id).toBe(target?.submissionId);
    expect(pinned?.grading?.selection.assessmentId).toBe(target?.assessmentId);
  });

  it("never names another teacher's class or assessment", async () => {
    const target = await findDefaultFocusTarget(world.teacherA, {
      classId: world.classB,
      assessmentId: world.assessmentB,
    });

    expect(target).toMatchObject({ classId: world.classA, assessmentId: world.assessmentA });
  });
});

describe("completion rate", () => {
  it("counts every assessment, not an arbitrary first batch", async () => {
    const extra = MAX_ASSESSMENTS + 5;
    await db.assessment.createMany({
      data: Array.from({ length: extra }, (_, index) => ({
        classId: world.classB,
        creatorId: world.teacherB.profileId,
        kind: "QUIZ" as const,
        subject: "MATH" as const,
        title: `Extra ${index}-${world.tag}`,
        status: "PUBLISHED" as const,
      })),
    });
    await db.assessment.create({
      data: {
        classId: world.classB,
        creatorId: world.teacherB.profileId,
        kind: "QUIZ",
        subject: "MATH",
        title: `Draft-${world.tag}`,
        status: "DRAFT",
      },
    });

    const first = await getTeacherWorkspace(world.teacherB, {});
    const second = await getTeacherWorkspace(world.teacherB, {});

    // One enrolled student: every published assessment is one expected submission.
    expect(first?.stats.completion).toEqual({
      percent: 0.9,
      submitted: 1,
      expected: extra + 1,
    });
    expect(second?.stats.completion).toEqual(first?.stats.completion);
  });
});

describe("pagination", () => {
  it("pages submissions with correct windows and clamps out-of-range pages", async () => {
    const extra = SUBMISSIONS_PAGE_SIZE + 2;
    for (let index = 0; index < extra; index += 1) {
      const student = await createEnrolledStudent(world.tag, `p${index}`, world.classA);
      await createSubmission(world.assessmentA, student, `#P${index}`);
    }
    const total = extra + 2;

    const first = await getTeacherWorkspace(world.teacherA, { page: 1 });
    const last = await getTeacherWorkspace(world.teacherA, { page: 99 });

    expect(first?.grading?.rows).toHaveLength(SUBMISSIONS_PAGE_SIZE);
    expect(first?.grading?.pagination).toMatchObject({
      totalItems: total,
      totalPages: 2,
      hasNext: true,
    });
    expect(last?.grading?.pagination.page).toBe(2);
    expect(last?.grading?.rows).toHaveLength(total - SUBMISSIONS_PAGE_SIZE);
  });

  it("pages lectures and lists only the teacher's own", async () => {
    const count = LECTURES_PAGE_SIZE + 1;
    await db.lesson.createMany({
      data: Array.from({ length: count }, (_, index) => ({
        authorId: world.teacherA.profileId,
        title: `Bai giang ${index}-${world.tag}`,
        durationSeconds: 600,
        status: "PUBLISHED" as const,
      })),
    });
    await db.lesson.create({
      data: {
        authorId: world.teacherB.profileId,
        title: `cua B-${world.tag}`,
        durationSeconds: 60,
      },
    });

    const page2 = await getTeacherWorkspace(world.teacherA, { lecturePage: 2 });

    // The shared world already owns one lesson for teacher A.
    const total = count + 1;
    expect(page2?.lectures.total).toBe(total);
    expect(page2?.lectures.items).toHaveLength(total - LECTURES_PAGE_SIZE);
    expect(JSON.stringify(page2?.lectures)).not.toContain("cua B");
  });
});

describe("insights", () => {
  it("returns the teacher's cached insight with ordered gaps", async () => {
    await db.teacherInsight.create({
      data: {
        teacherId: world.teacherA.profileId,
        scannedSubmissions: 7,
        remediationIntro: "a",
        remediationLecture: "b",
        remediationOutro: "c",
        gaps: {
          create: [
            { position: 1, topic: "T2", percent: 28, tone: "CONFUSED", note: "n" },
            { position: 0, topic: "T1", percent: 68, tone: "MASTERED", note: "n" },
          ],
        },
      },
    });

    const workspace = await getTeacherWorkspace(world.teacherA, {});
    const other = await getTeacherWorkspace(world.teacherB, {});

    expect(workspace?.insights?.gaps.map((gap) => gap.topic)).toEqual(["T1", "T2"]);
    expect(other?.insights).toBeNull();
  });
});
