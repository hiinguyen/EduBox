import { describe, expect, it } from "vitest";
import { MAX_CREDITED_SECONDS_PER_UPDATE } from "./constants";
import { computeCourseProgress, computeCreditedSeconds } from "./progress-math";

const NOW = new Date("2026-11-11T05:00:00Z");
const secondsAgo = (seconds: number) => new Date(NOW.getTime() - seconds * 1_000);

describe("computeCreditedSeconds", () => {
  it("credits the forward move since the last saved position", () => {
    const previous = { positionSeconds: 100, updatedAt: secondsAgo(120) };

    expect(computeCreditedSeconds({ previous, positionSeconds: 160, now: NOW })).toBe(60);
  });

  it("credits nothing when the student seeks backwards", () => {
    const previous = { positionSeconds: 400, updatedAt: secondsAgo(120) };

    expect(computeCreditedSeconds({ previous, positionSeconds: 100, now: NOW })).toBe(0);
  });

  it("caps a long seek at the per-call limit", () => {
    const previous = { positionSeconds: 0, updatedAt: secondsAgo(86_400) };

    const credited = computeCreditedSeconds({ previous, positionSeconds: 5_000, now: NOW });

    expect(credited).toBe(MAX_CREDITED_SECONDS_PER_UPDATE);
  });

  it("never credits more than the wall-clock time since the last save", () => {
    const previous = { positionSeconds: 0, updatedAt: secondsAgo(10) };

    expect(computeCreditedSeconds({ previous, positionSeconds: 500, now: NOW })).toBe(10);
  });

  it("caps the first save from zero", () => {
    expect(computeCreditedSeconds({ previous: null, positionSeconds: 5_000, now: NOW })).toBe(
      MAX_CREDITED_SECONDS_PER_UPDATE,
    );
  });
});

describe("computeCourseProgress", () => {
  it("points at the lesson after the highest completed one", () => {
    expect(computeCourseProgress([1, 2, 4], 10)).toEqual({ currentLesson: 5, progressPercent: 30 });
  });

  it("starts at lesson 1 with no completed lesson", () => {
    expect(computeCourseProgress([], 10)).toEqual({ currentLesson: 1, progressPercent: 0 });
  });

  it("stays within the course length when everything is complete", () => {
    expect(computeCourseProgress([1, 2, 3], 3)).toEqual({ currentLesson: 3, progressPercent: 100 });
  });

  it("counts unnumbered lessons toward the percent only", () => {
    expect(computeCourseProgress([null, 2], 4)).toEqual({ currentLesson: 3, progressPercent: 50 });
  });
});
