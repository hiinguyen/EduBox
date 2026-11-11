import { afterAll, beforeAll, beforeEach, describe, expect, it } from "vitest";
import { db } from "@/lib/db";
import { createHocTapWorld, type HocTapWorld } from "@/test/hoc-tap-world";
import { MAX_NOTES_PER_LESSON, NOTE_RATE_LIMIT, NOTE_RATE_WINDOW_MS } from "./constants";
import { saveLessonNote } from "./lesson-actions";

let world: HocTapWorld;

const note = (atSeconds = 10) => ({ lessonId: world.lessonId, atSeconds, body: "ghi chú" });

async function seedNotes(count: number): Promise<void> {
  await db.note.createMany({
    data: Array.from({ length: count }, (_, index) => ({
      studentId: world.studentA.profileId,
      lessonId: world.lessonId,
      atSeconds: index,
      body: `n${index}`,
    })),
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
  await db.note.deleteMany({ where: { studentId: world.studentA.profileId } });
  await db.rateLimitBucket.deleteMany({ where: { key: { contains: world.studentA.id } } });
});

describe("saveLessonNote cap", () => {
  it("rejects the note beyond the per-lesson cap and stores nothing more", async () => {
    await seedNotes(MAX_NOTES_PER_LESSON);

    const result = await saveLessonNote(world.studentA, note());

    expect(result).toMatchObject({ ok: false, error: { code: "CONFLICT" } });
    expect(result.ok ? "" : result.error.message).toContain(String(MAX_NOTES_PER_LESSON));
    expect(await db.note.count({ where: { studentId: world.studentA.profileId } })).toBe(
      MAX_NOTES_PER_LESSON,
    );
  });

  it("accepts the last note that still fits under the cap", async () => {
    await seedNotes(MAX_NOTES_PER_LESSON - 1);

    const result = await saveLessonNote(world.studentA, note());

    expect(result.ok).toBe(true);
  });

  it("counts notes per lesson, so another lesson is not capped", async () => {
    await seedNotes(MAX_NOTES_PER_LESSON);

    const result = await saveLessonNote(world.studentA, {
      ...note(),
      lessonId: world.courseLessonIds[0],
    });

    expect(result.ok).toBe(true);
  });
});

describe("saveLessonNote rate limit", () => {
  it("blocks saves past the per-minute limit and writes nothing for the blocked one", async () => {
    await db.rateLimitBucket.create({
      data: {
        key: `note-save:${world.studentA.id}`,
        count: NOTE_RATE_LIMIT,
        windowStart: new Date(Date.now() - NOTE_RATE_WINDOW_MS / 2),
      },
    });

    const result = await saveLessonNote(world.studentA, note());

    expect(result).toMatchObject({ ok: false, error: { code: "RATE_LIMITED" } });
    expect(await db.note.count({ where: { studentId: world.studentA.profileId } })).toBe(0);
  });

  it("allows a student who is under the limit", async () => {
    const results = await Promise.all(
      [1, 2, 3].map((at) => saveLessonNote(world.studentA, note(at))),
    );

    expect(results.every((result) => result.ok)).toBe(true);
  });
});
