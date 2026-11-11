import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import type { ActionAuthResult, SessionUser } from "@/lib/auth/session";
import { db } from "@/lib/db";
import { MAX_NOTE_LENGTH } from "./constants";
import { createHocTapWorld, type HocTapWorld } from "@/test/hoc-tap-world";

const authState = vi.hoisted(() => ({ current: null as unknown }));

vi.mock("@/lib/auth/session", () => ({
  requireRoleForAction: async (): Promise<ActionAuthResult> => {
    const user = authState.current as SessionUser | null;
    if (!user) {
      return { ok: false, error: { code: "UNAUTHENTICATED", message: "x" } };
    }
    if (user.role !== "STUDENT") {
      return { ok: false, error: { code: "FORBIDDEN", message: "x" } };
    }
    return { ok: true, user };
  },
}));

const { saveLessonNoteAction, updateLessonProgressAction } = await import("./actions");
const { getHocTapOverview } = await import("./overview");

let world: HocTapWorld;

beforeAll(async () => {
  world = await createHocTapWorld();
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

beforeEach(async () => {
  authState.current = world.studentA;
  const studentIds = [world.studentA.profileId, world.studentB.profileId];
  await db.note.deleteMany({ where: { studentId: { in: studentIds } } });
  await db.lessonProgress.deleteMany({ where: { studentId: { in: studentIds } } });
});

describe("getHocTapOverview", () => {
  it("returns the student's own lesson, course, material and homework", async () => {
    const overview = await getHocTapOverview(world.studentA);

    expect(overview.lesson?.id).toBe(world.lessonId);
    expect(overview.lesson?.chapters.map((chapter) => chapter.title)).toEqual([
      "Mở đầu",
      "Trọng tâm",
    ]);
    expect(overview.courses.map((course) => course.title)).toContain(`course-${world.tag}`);
    expect(overview.courses[0]?.instructor).toBe("Cô Test · Bài 3/10");
    expect(overview.homework?.title).toBe(world.assessmentTitle);
    expect(overview.summary.studentFirstName).toBe("Minh Anh");
  });

  it("shows a student without enrolment no lesson, course or homework of another class", async () => {
    const overview = await getHocTapOverview(world.studentB);

    expect(overview.lesson).toBeNull();
    expect(overview.courses).toEqual([]);
    expect(overview.homework).toBeNull();
  });
});

describe("saveLessonNoteAction", () => {
  const input = () => ({ lessonId: world.lessonId, atSeconds: 120, body: "Nhớ xét dấu f'(x)" });

  it("persists a note for the signed-in student and returns it", async () => {
    const result = await saveLessonNoteAction(input());

    expect(result.ok).toBe(true);
    const stored = await db.note.findMany({ where: { studentId: world.studentA.profileId } });
    expect(stored.map((note) => note.body)).toContain("Nhớ xét dấu f'(x)");
  });

  it("loads the saved note back into the overview", async () => {
    await saveLessonNoteAction(input());

    const overview = await getHocTapOverview(world.studentA);

    expect(overview.lesson?.notes.map((note) => note.atSeconds)).toContain(120);
  });

  it("returns UNAUTHENTICATED when nobody is signed in", async () => {
    authState.current = null;

    const result = await saveLessonNoteAction(input());

    expect(result).toMatchObject({ ok: false, error: { code: "UNAUTHENTICATED" } });
  });

  it.each([
    ["parent", () => world.parent],
    ["teacher", () => world.teacher],
  ])("returns FORBIDDEN for a %s", async (_label, pick) => {
    authState.current = pick();

    const result = await saveLessonNoteAction(input());

    expect(result).toMatchObject({ ok: false, error: { code: "FORBIDDEN" } });
  });

  it("rejects a lesson the student cannot see and writes nothing", async () => {
    const result = await saveLessonNoteAction({ ...input(), lessonId: world.otherLessonId });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.note.count({ where: { lessonId: world.otherLessonId } })).toBe(0);
  });

  it("does not let student B write a note on a lesson of A's class", async () => {
    authState.current = world.studentB;

    const result = await saveLessonNoteAction(input());

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    expect(await db.note.count({ where: { studentId: world.studentB.profileId } })).toBe(0);
  });

  it("rejects an over-length note with a Vietnamese message", async () => {
    const result = await saveLessonNoteAction({
      ...input(),
      body: "a".repeat(MAX_NOTE_LENGTH + 1),
    });

    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
  });

  it("never exposes student A's notes in student B's overview", async () => {
    await saveLessonNoteAction(input());

    const overview = await getHocTapOverview(world.studentB);

    expect(overview.lesson?.notes ?? []).toEqual([]);
  });
});

describe("updateLessonProgressAction", () => {
  it("stores the position and resumes the lesson from it", async () => {
    const result = await updateLessonProgressAction({
      lessonId: world.lessonId,
      positionSeconds: 300,
    });

    expect(result).toEqual({ ok: true, data: { positionSeconds: 300, isCompleted: false } });
    const overview = await getHocTapOverview(world.studentA);
    expect(overview.lesson?.positionSeconds).toBe(300);
  });

  it("records completion when asked", async () => {
    const result = await updateLessonProgressAction({
      lessonId: world.lessonId,
      positionSeconds: 600,
      isCompleted: true,
    });

    expect(result).toMatchObject({ ok: true, data: { isCompleted: true } });
  });

  it("denies another student, a parent and an anonymous caller", async () => {
    const input = { lessonId: world.lessonId, positionSeconds: 10 };

    authState.current = world.studentB;
    expect(await updateLessonProgressAction(input)).toMatchObject({ error: { code: "NOT_FOUND" } });
    authState.current = world.parent;
    expect(await updateLessonProgressAction(input)).toMatchObject({ error: { code: "FORBIDDEN" } });
    authState.current = null;
    expect(await updateLessonProgressAction(input)).toMatchObject({
      error: { code: "UNAUTHENTICATED" },
    });
    expect(await db.lessonProgress.count({ where: { studentId: world.studentB.profileId } })).toBe(
      0,
    );
  });

  it("rejects a negative position", async () => {
    const result = await updateLessonProgressAction({
      lessonId: world.lessonId,
      positionSeconds: -5,
    });

    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
  });
});
