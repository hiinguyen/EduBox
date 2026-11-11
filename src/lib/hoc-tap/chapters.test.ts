import { describe, expect, it } from "vitest";
import { findCurrentChapterId } from "./chapters";
import type { LessonChapter } from "./types";

function chapter(id: string, startSeconds: number): LessonChapter {
  return { id, startSeconds, title: id, note: "n", currentNote: "c" };
}

describe("findCurrentChapterId", () => {
  const chapters = [chapter("a", 60), chapter("b", 300), chapter("c", 900)];

  it("returns the latest chapter that has already started", () => {
    expect(findCurrentChapterId(chapters, 400)).toBe("b");
  });

  it("returns null before the first chapter starts", () => {
    expect(findCurrentChapterId(chapters, 10)).toBeNull();
  });

  it("returns the chapter that starts exactly at the position", () => {
    expect(findCurrentChapterId(chapters, 900)).toBe("c");
  });
});
