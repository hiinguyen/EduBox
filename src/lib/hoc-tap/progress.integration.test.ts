import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { db } from "@/lib/db";
import { getVnCalendarDay } from "@/lib/format/date";
import { MS_PER_MINUTE } from "@/lib/format/time";
import { createHocTapWorld, type HocTapWorld } from "@/test/hoc-tap-world";
import { MAX_CREDITED_SECONDS_PER_UPDATE } from "./constants";
import { updateLessonProgress } from "./lesson-actions";

let world: HocTapWorld;

const progress = (positionSeconds: number, isCompleted?: boolean, lessonId = world.lessonId) => ({
  lessonId,
  positionSeconds,
  ...(isCompleted === undefined ? {} : { isCompleted }),
});

async function studiedSeconds(): Promise<number> {
  const rows = await db.studyDay.findMany({ where: { studentId: world.studentA.profileId } });
  return rows.reduce((total, row) => total + row.studiedSeconds, 0);
}

/** Pretends the last save happened a while ago so the wall-clock cap does not hide the delta. */
async function ageProgress(lessonId: string, minutes: number): Promise<void> {
  await db.lessonProgress.update({
    where: { studentId_lessonId: { studentId: world.studentA.profileId, lessonId } },
    data: { updatedAt: new Date(Date.now() - minutes * MS_PER_MINUTE) },
  });
}

beforeAll(async () => {
  world = await createHocTapWorld();
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

beforeEach(async () => {
  const where = { studentId: world.studentA.profileId };
  await db.lessonProgress.deleteMany({ where });
  await db.studyDay.deleteMany({ where });
  await db.activityLog.deleteMany({ where });
  await db.lesson.updateMany({ data: { viewCount: 0 }, where: { title: { endsWith: world.tag } } });
  await db.courseEnrollment.updateMany({
    where: { courseId: world.courseId, ...where },
    data: { currentLesson: 3, progressPercent: 30 },
  });
});

describe("study time", () => {
  it("credits the forward move since the last save to today's study day", async () => {
    await updateLessonProgress(world.studentA, progress(0));
    await ageProgress(world.lessonId, 10);
    const before = await studiedSeconds();

    await updateLessonProgress(world.studentA, progress(120));

    expect((await studiedSeconds()) - before).toBe(120);
    const day = await db.studyDay.findFirst({ where: { studentId: world.studentA.profileId } });
    expect(day?.day.toISOString().slice(0, 10)).toBe(getVnCalendarDay(new Date()));
  });

  it("caps a long seek so it cannot fake hours", async () => {
    await updateLessonProgress(world.studentA, progress(0));
    await ageProgress(world.lessonId, 600);

    await updateLessonProgress(world.studentA, progress(5_000));

    expect(await studiedSeconds()).toBe(MAX_CREDITED_SECONDS_PER_UPDATE);
  });

  it("credits nothing for a backward seek", async () => {
    await updateLessonProgress(world.studentA, progress(400));
    await ageProgress(world.lessonId, 10);
    const before = await studiedSeconds();

    await updateLessonProgress(world.studentA, progress(100));

    expect(await studiedSeconds()).toBe(before);
  });

  it("never credits more than the time that really passed since the last save", async () => {
    await updateLessonProgress(world.studentA, progress(0));

    await updateLessonProgress(world.studentA, progress(300));

    expect(await studiedSeconds()).toBeLessThan(5);
  });
});

describe("view count", () => {
  it("increments only when the progress row is first created", async () => {
    await updateLessonProgress(world.studentA, progress(10));
    await updateLessonProgress(world.studentA, progress(20));

    const lesson = await db.lesson.findUniqueOrThrow({ where: { id: world.lessonId } });
    expect(lesson.viewCount).toBe(1);
  });

  it("does not count a rejected save for a lesson the student cannot see", async () => {
    const result = await updateLessonProgress(
      world.studentA,
      progress(10, false, world.otherLessonId),
    );

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    const lesson = await db.lesson.findUniqueOrThrow({ where: { id: world.otherLessonId } });
    expect(lesson.viewCount).toBe(0);
  });
});

describe("activity", () => {
  const activities = () =>
    db.activityLog.findMany({ where: { studentId: world.studentA.profileId } });

  it("records one LECTURE_WATCHED activity the first time a lesson is completed", async () => {
    await updateLessonProgress(world.studentA, progress(600, true));
    await updateLessonProgress(world.studentA, progress(600, true));

    const rows = await activities();
    expect(rows).toHaveLength(1);
    expect(rows[0]).toMatchObject({
      kind: "LECTURE_WATCHED",
      title: `Xem hết bài giảng "A-${world.tag}"`,
      tags: [{ label: "Hoàn thành 100% video", tone: "success" }],
    });
    expect(rows[0]?.description).toEqual([
      { text: "Thời lượng bài giảng: " },
      { text: "10 phút", isEmphasis: true },
      { text: "." },
    ]);
  });

  it("records nothing for a save that does not complete the lesson", async () => {
    await updateLessonProgress(world.studentA, progress(300));

    expect(await activities()).toHaveLength(0);
  });

  it("records the activity when an existing row is completed later", async () => {
    await updateLessonProgress(world.studentA, progress(300));
    await updateLessonProgress(world.studentA, progress(600, true));

    expect(await activities()).toHaveLength(1);
  });
});

describe("course enrollment", () => {
  const enrollment = () =>
    db.courseEnrollment.findUniqueOrThrow({
      where: {
        courseId_studentId: { courseId: world.courseId, studentId: world.studentA.profileId },
      },
    });

  it("recomputes the current lesson and percent from the completed lessons", async () => {
    const [, third] = world.courseLessonIds;

    await updateLessonProgress(world.studentA, progress(600, true));
    await updateLessonProgress(world.studentA, progress(600, true, third));

    expect(await enrollment()).toMatchObject({ currentLesson: 4, progressPercent: 20 });
  });

  it("moves back when a lesson is marked not completed again", async () => {
    await updateLessonProgress(world.studentA, progress(600, true));
    await updateLessonProgress(world.studentA, progress(100, false));

    expect(await enrollment()).toMatchObject({ currentLesson: 1, progressPercent: 0 });
  });

  it("leaves the enrollment alone when nothing was completed", async () => {
    await updateLessonProgress(world.studentA, progress(300));

    expect(await enrollment()).toMatchObject({ currentLesson: 3, progressPercent: 30 });
  });

  it("does not create an enrollment for a course the student never joined", async () => {
    await db.courseEnrollment.deleteMany({ where: { courseId: world.courseId } });

    await updateLessonProgress(world.studentA, progress(600, true));

    expect(await db.courseEnrollment.count({ where: { courseId: world.courseId } })).toBe(0);
  });
});
