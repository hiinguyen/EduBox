import { describe, expect, it } from "vitest";
import { buildEffortHighlight, computeStreakDays, type StudyDaySample } from "./effort";

/** 19:00 on 11/11/2026 in Vietnam. */
const TODAY = new Date("2026-11-11T12:00:00Z");
const ENOUGH = 3600;

function dayAgo(offset: number, studiedSeconds = ENOUGH): StudyDaySample {
  return { day: new Date(Date.UTC(2026, 10, 11 - offset)), studiedSeconds };
}

describe("computeStreakDays", () => {
  it("counts consecutive qualifying days ending today", () => {
    expect(computeStreakDays([dayAgo(0), dayAgo(1), dayAgo(2)], TODAY)).toBe(3);
  });

  it("keeps the streak alive when today has no study yet", () => {
    expect(computeStreakDays([dayAgo(1), dayAgo(2)], TODAY)).toBe(2);
  });

  it("stops at the first gap", () => {
    expect(computeStreakDays([dayAgo(0), dayAgo(1), dayAgo(3)], TODAY)).toBe(2);
  });

  it("ignores days below the minimum study time", () => {
    expect(computeStreakDays([dayAgo(0, 60), dayAgo(1)], TODAY)).toBe(1);
  });

  it("returns zero without any qualifying day", () => {
    expect(computeStreakDays([], TODAY)).toBe(0);
  });
});

describe("computeStreakDays at Vietnam day boundaries", () => {
  it("counts the Vietnam day at 23:00 UTC (06:00 the next day) as today", () => {
    const now = new Date("2026-11-11T23:00:00Z");

    expect(computeStreakDays([dayAgo(-1), dayAgo(0)], now)).toBe(2);
  });

  it("still counts the previous Vietnam day at 17:00 UTC (00:00 the next day)", () => {
    const now = new Date("2026-11-11T17:00:00Z");

    expect(computeStreakDays([dayAgo(0), dayAgo(1)], now)).toBe(2);
    expect(computeStreakDays([dayAgo(2)], now)).toBe(0);
  });
});

describe("buildEffortHighlight", () => {
  it("prefers a recently earned badge", () => {
    const effort = buildEffortHighlight({
      givenName: "Minh Anh",
      streakDays: 5,
      recentBadgeTitle: "Chiến binh Chăm chỉ",
    });

    expect(effort.title).toBe("Minh Anh vừa đạt Chiến binh Chăm chỉ");
  });

  it("celebrates the streak otherwise", () => {
    const effort = buildEffortHighlight({
      givenName: "Minh Anh",
      streakDays: 5,
      recentBadgeTitle: null,
    });

    expect(effort.title).toBe("Minh Anh đã tự giác học 5 ngày liên tục");
  });

  it("encourages the habit when there is no streak", () => {
    const effort = buildEffortHighlight({
      givenName: "Gia Bảo",
      streakDays: 0,
      recentBadgeTitle: null,
    });

    expect(effort.title).toContain("Gia Bảo");
  });
});
