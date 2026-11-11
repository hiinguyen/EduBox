import { describe, expect, it } from "vitest";
import { MIN_STREAK_SECONDS, computeStreak } from "./streak";

const ENOUGH = MIN_STREAK_SECONDS;
const day = (value: string, studiedSeconds = ENOUGH) => ({ day: value, studiedSeconds });

describe("computeStreak", () => {
  it("is 15 minutes", () => {
    expect(MIN_STREAK_SECONDS).toBe(900);
  });

  it("counts consecutive days ending today", () => {
    const days = [day("2026-11-10"), day("2026-11-11"), day("2026-11-12")];

    expect(computeStreak(days, "2026-11-12")).toBe(3);
  });

  it("counts from yesterday when today has no study yet", () => {
    const days = [day("2026-11-10"), day("2026-11-11")];

    expect(computeStreak(days, "2026-11-12")).toBe(2);
  });

  it("is zero when neither today nor yesterday qualifies", () => {
    expect(computeStreak([day("2026-11-09")], "2026-11-12")).toBe(0);
  });

  it("stops at a gap", () => {
    const days = [day("2026-11-08"), day("2026-11-10"), day("2026-11-11")];

    expect(computeStreak(days, "2026-11-11")).toBe(2);
  });

  it("ignores days below the minimum study time", () => {
    const days = [day("2026-11-11", ENOUGH - 1), day("2026-11-10")];

    expect(computeStreak(days, "2026-11-11")).toBe(1);
  });

  it("walks across month boundaries", () => {
    const days = [day("2026-10-31"), day("2026-11-01")];

    expect(computeStreak(days, "2026-11-01")).toBe(2);
  });

  it("is not inflated by duplicate rows", () => {
    expect(computeStreak([day("2026-11-11"), day("2026-11-11")], "2026-11-11")).toBe(1);
  });
});
