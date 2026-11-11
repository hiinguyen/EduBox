import { afterAll, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { db } from "@/lib/db";
import { createPhuHuynhWorld, seedChildData, type PhuHuynhWorld } from "@/test/phu-huynh-world";
import { WRITE_RATE_LIMIT } from "./constants";

const authMock = vi.hoisted(() => vi.fn());
const rateLimitMock = vi.hoisted(() => vi.fn());
vi.mock("@/lib/auth/auth", () => ({ auth: authMock }));
vi.mock("next/cache", () => ({ revalidatePath: vi.fn() }));
vi.mock("@/lib/rate-limit", async (importOriginal) => {
  const actual = await importOriginal<typeof import("@/lib/rate-limit")>();
  rateLimitMock.mockImplementation(actual.rateLimit);
  return { ...actual, rateLimit: rateLimitMock };
});

import { acknowledgeNoteAction, setCompanionSettingAction } from "./actions";
import { getParentDashboard, type DashboardResult } from "./dashboard";

let ctx: PhuHuynhWorld;
let seededA: Awaited<ReturnType<typeof seedChildData>>;

/** Study days far from the real clock so seeded rows never collide with the current week. */
const studyDay = (day: string) => new Date(`${day}T00:00:00.000Z`);
/** 06:00 on Wed 12/03/2031 in Vietnam, still Tuesday 23:00 in UTC. */
const WED_MORNING_VN = new Date("2031-03-11T23:00:00Z");
/** 00:00 on Mon 17/03/2031 in Vietnam, still Sunday 17:00 in UTC. */
const MON_MIDNIGHT_VN = new Date("2031-03-16T17:00:00Z");

beforeAll(async () => {
  ctx = await createPhuHuynhWorld();
  const { world } = ctx;
  seededA = await seedChildData(ctx, world.childA, world.submissionA, world.teacherA);
  await seedChildData(ctx, world.childB, world.submissionB, world.teacherB);
  await db.lessonProgress.create({
    data: { studentId: world.childB, lessonId: world.lessonA, isCompleted: true },
  });
  const days: ReadonlyArray<readonly [string, number]> = [
    ["2031-03-09", 3600],
    ["2031-03-10", 3600],
    ["2031-03-11", 3600],
    ["2031-03-12", 1800],
    ["2031-03-16", 3600],
    ["2031-03-17", 1200],
  ];
  await db.studyDay.createMany({
    data: days.map(([day, studiedSeconds]) => ({
      studentId: world.childB,
      day: studyDay(day),
      studiedSeconds,
    })),
  });
});

afterAll(async () => {
  await ctx.cleanup();
  await db.$disconnect();
});

beforeEach(() => {
  authMock.mockReset();
});

function signInAs(userId: string | null): void {
  authMock.mockResolvedValue(userId ? { user: { id: userId } } : null);
}

function viewer(parentId: string) {
  return { profileId: parentId, name: "Phụ huynh" };
}

function readyDashboard(result: DashboardResult) {
  if (result.status !== "ready")
    throw new Error(`expected a ready dashboard, got ${result.status}`);
  return result.dashboard;
}

describe("getParentDashboard", () => {
  it("defaults to the parent's first child and builds every section from the database", async () => {
    const dashboard = readyDashboard(await getParentDashboard(viewer(ctx.world.parentA)));

    expect(dashboard.selectedChild.id).toBe(ctx.world.childA);
    expect(dashboard.children.map((child) => child.id)).toEqual([ctx.world.childA]);
    expect(dashboard.stats.find((stat) => stat.id === "online-time")?.value).toBe("2");
    expect(dashboard.stats.find((stat) => stat.id === "average-score")?.value).toBe(
      String(seededA.gradedEarned),
    );
    expect(dashboard.stats.find((stat) => stat.id === "ai-questions")?.value).toBe("1");
    expect(dashboard.activity).toHaveLength(1);
    expect(dashboard.progress?.series[0]?.scores).toEqual([seededA.mathScore]);
    expect(dashboard.teacherNote?.id).toBe(ctx.noteA);
    expect(dashboard.upcoming.map((task) => task.id)).toEqual([ctx.dueAssessmentA]);
    expect(dashboard.effort.title).toContain("vừa đạt");
    expect(dashboard.linkedDevices.label).toContain(ctx.tag);
    expect(dashboard.settings.every((setting) => setting.isEnabled)).toBe(true);
  });

  it("does not leak the owning parent id into the view model", async () => {
    const dashboard = await getParentDashboard(viewer(ctx.world.parentA));

    expect(JSON.stringify(dashboard)).not.toContain(ctx.world.parentA);
  });

  it("answers another family's child exactly like an unknown id", async () => {
    const foreign = await getParentDashboard(viewer(ctx.world.parentA), ctx.world.childB);
    const unknown = await getParentDashboard(viewer(ctx.world.parentA), "does-not-exist");

    expect(foreign).toEqual({ status: "not-found" });
    expect(unknown).toEqual(foreign);
  });

  it("reports an empty state for a parent without linked children", async () => {
    const result = await getParentDashboard(viewer(ctx.parentWithoutChildren));

    expect(result).toEqual({ status: "no-children" });
  });

  it("still answers not-found for a requested child when the parent has none", async () => {
    const result = await getParentDashboard(viewer(ctx.parentWithoutChildren), ctx.world.childA);

    expect(result).toEqual({ status: "not-found" });
  });
});

describe("weekly statistics in Vietnam time", () => {
  it("sums the Monday-start week and counts Sunday only for the streak (06:00 VN, 23:00 UTC)", async () => {
    const dashboard = readyDashboard(
      await getParentDashboard(viewer(ctx.world.parentB), undefined, WED_MORNING_VN),
    );

    const onlineTime = dashboard.stats.find((stat) => stat.id === "online-time");
    expect(onlineTime?.value).toBe("2.5");
    expect(dashboard.effort.title).toContain("4 ngày liên tục");
  });

  it("starts a new week at Vietnam midnight (00:00 VN, 17:00 UTC)", async () => {
    const dashboard = readyDashboard(
      await getParentDashboard(viewer(ctx.world.parentB), undefined, MON_MIDNIGHT_VN),
    );

    const onlineTime = dashboard.stats.find((stat) => stat.id === "online-time");
    expect(onlineTime?.value).toBe("0.3");
    expect(dashboard.effort.title).toContain("2 ngày liên tục");
  });

  it("counts only lessons updated since the Vietnam week began", async () => {
    const thisWeek = readyDashboard(await getParentDashboard(viewer(ctx.world.parentB)));
    const beforeWeekStart = readyDashboard(
      await getParentDashboard(
        viewer(ctx.world.parentB),
        undefined,
        new Date("2031-03-11T23:00:00Z"),
      ),
    );

    expect(thisWeek.stats.find((stat) => stat.id === "lectures")?.value).toBe("1");
    expect(beforeWeekStart.stats.find((stat) => stat.id === "lectures")?.value).toBe("0");
  });
});

describe("student queries stay scoped to the parent's own children", () => {
  it("returns nothing of another family's child through any helper", async () => {
    const queries = await import("./student-queries");
    const { parentA, childB } = ctx.world;
    const now = new Date();

    expect(await queries.loadStudyDays(parentA, childB, now)).toEqual([]);
    expect(await queries.loadStudiedSeconds(parentA, childB, now)).toBe(0);
    expect(await queries.loadLessonCounts(parentA, childB, now)).toEqual({
      watched: 0,
      completed: 0,
    });
    expect(await queries.loadWeekScores(parentA, childB)).toEqual([]);
    expect(await queries.loadDeviceNames(parentA, childB)).toEqual([]);
    expect(await queries.loadRecentBadgeTitle(parentA, childB, now)).toBeNull();
    expect(await queries.countAiQuestions(parentA, childB, now)).toBe(0);
    expect(await queries.loadActivity(parentA, childB)).toEqual([]);
    expect(await queries.loadLatestNote(parentA, childB)).toBeNull();
    expect(await queries.loadUpcoming(parentA, childB, now)).toEqual([]);
    expect(await queries.loadGradeSamples(parentA, childB, now)).toEqual([]);
  });

  it("returns the same data to the owning parent", async () => {
    const queries = await import("./student-queries");
    const { parentB, childB } = ctx.world;
    const now = new Date();

    expect((await queries.loadStudyDays(parentB, childB, now)).length).toBeGreaterThan(0);
    expect(await queries.loadDeviceNames(parentB, childB)).toHaveLength(1);
    expect(await queries.loadRecentBadgeTitle(parentB, childB, now)).toContain(ctx.tag);
    expect(await queries.countAiQuestions(parentB, childB, now)).toBe(1);
  });
});

describe("setCompanionSettingAction", () => {
  const input = (childId: string) => ({ childId, settingId: "night-limit", isEnabled: false });

  it("rejects an anonymous caller", async () => {
    signInAs(null);

    const result = await setCompanionSettingAction(input(ctx.world.childA));

    expect(result).toMatchObject({ ok: false, error: { code: "UNAUTHENTICATED" } });
  });

  it("rejects students and teachers", async () => {
    signInAs(ctx.users.studentA);
    expect(await setCompanionSettingAction(input(ctx.world.childA))).toMatchObject({
      ok: false,
      error: { code: "FORBIDDEN" },
    });
    signInAs(ctx.users.teacherA);
    expect(await setCompanionSettingAction(input(ctx.world.childA))).toMatchObject({
      ok: false,
      error: { code: "FORBIDDEN" },
    });
  });

  it("rejects malformed input", async () => {
    signInAs(ctx.users.parentA);
    const valid = input(ctx.world.childA);

    for (const bad of [
      null,
      { ...valid, settingId: "other" },
      { ...valid, isEnabled: "yes" },
      { ...valid, childId: "../etc" },
    ]) {
      expect(await setCompanionSettingAction(bad)).toMatchObject({
        ok: false,
        error: { code: "INVALID_INPUT" },
      });
    }
  });

  it("does not let parent A change parent B's child or create settings for it", async () => {
    signInAs(ctx.users.parentA);

    const result = await setCompanionSettingAction(input(ctx.world.childB));

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    const rows = await db.parentSettings.count({ where: { studentId: ctx.world.childB } });
    expect(rows).toBe(0);
  });

  it("persists the toggle so a fresh dashboard load reflects it", async () => {
    signInAs(ctx.users.parentA);

    const result = await setCompanionSettingAction({
      ...input(ctx.world.childA),
      settingId: "instant-alerts",
    });

    expect(result).toEqual({ ok: true, data: null });
    const dashboard = readyDashboard(await getParentDashboard(viewer(ctx.world.parentA)));
    expect(dashboard.settings.map((setting) => [setting.id, setting.isEnabled])).toEqual([
      ["night-limit", true],
      ["instant-alerts", false],
    ]);
    const other = readyDashboard(await getParentDashboard(viewer(ctx.world.parentB)));
    expect(other.settings.every((setting) => setting.isEnabled)).toBe(true);
  });

  it("rate limits repeated writes", async () => {
    signInAs(ctx.users.parentB);
    const results = [];
    for (let attempt = 0; attempt <= WRITE_RATE_LIMIT.limit; attempt += 1) {
      results.push(
        await setCompanionSettingAction({ ...input(ctx.world.childB), isEnabled: true }),
      );
    }

    expect(results.at(-1)).toMatchObject({ ok: false, error: { code: "RATE_LIMITED" } });
  });

  it("returns INTERNAL instead of throwing when the limiter fails", async () => {
    signInAs(ctx.users.parentA);
    const stderr = vi.spyOn(process.stderr, "write").mockImplementation(() => true);
    rateLimitMock.mockRejectedValueOnce(new Error("database unavailable"));

    const result = await setCompanionSettingAction(input(ctx.world.childA));

    expect(result).toMatchObject({ ok: false, error: { code: "INTERNAL" } });
    expect(JSON.stringify(stderr.mock.calls)).not.toContain("database unavailable");
    stderr.mockRestore();
  });
});

describe("acknowledgeNoteAction", () => {
  it("rejects anonymous callers and other roles", async () => {
    signInAs(null);
    expect(await acknowledgeNoteAction({ noteId: ctx.noteA })).toMatchObject({
      error: { code: "UNAUTHENTICATED" },
    });
    signInAs(ctx.users.teacherA);
    expect(await acknowledgeNoteAction({ noteId: ctx.noteA })).toMatchObject({
      error: { code: "FORBIDDEN" },
    });
  });

  it("rejects a malformed note id", async () => {
    signInAs(ctx.users.parentA);

    expect(await acknowledgeNoteAction({ noteId: "" })).toMatchObject({
      error: { code: "INVALID_INPUT" },
    });
  });

  it("returns INTERNAL instead of throwing when the limiter fails", async () => {
    signInAs(ctx.users.parentA);
    const stderr = vi.spyOn(process.stderr, "write").mockImplementation(() => true);
    rateLimitMock.mockRejectedValueOnce(new Error("database unavailable"));

    const result = await acknowledgeNoteAction({ noteId: ctx.noteA });

    expect(result).toMatchObject({ ok: false, error: { code: "INTERNAL" } });
    stderr.mockRestore();
  });

  it("does not let a parent acknowledge another family's note", async () => {
    signInAs(ctx.users.parentA);

    const result = await acknowledgeNoteAction({ noteId: ctx.noteB });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    const note = await db.parentTeacherNote.findUnique({ where: { id: ctx.noteB } });
    expect(note?.acknowledgedAt).toBeNull();
  });

  it("marks an owned note as read and stays idempotent", async () => {
    signInAs(ctx.users.parentA);

    expect(await acknowledgeNoteAction({ noteId: ctx.noteA })).toEqual({ ok: true, data: null });
    expect(await acknowledgeNoteAction({ noteId: ctx.noteA })).toEqual({ ok: true, data: null });

    const note = await db.parentTeacherNote.findUnique({ where: { id: ctx.noteA } });
    expect(note?.acknowledgedById).toBe(ctx.world.parentA);
    const dashboard = readyDashboard(await getParentDashboard(viewer(ctx.world.parentA)));
    expect(dashboard.teacherNote?.isAcknowledged).toBe(true);
  });
});
