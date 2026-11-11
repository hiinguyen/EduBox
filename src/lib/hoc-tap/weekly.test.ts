import { describe, expect, it } from "vitest";
import { badgeHint, computeWeeklyStats, isoWeekNumber, toCalendarDayKey } from "./weekly";

const HOUR = 3_600;
const NOW = new Date("2026-11-11T05:00:00Z");

describe("toCalendarDayKey", () => {
  it("reads a date column back as its calendar day", () => {
    expect(toCalendarDayKey(new Date("2026-11-11T00:00:00Z"))).toBe("2026-11-11");
  });
});

describe("isoWeekNumber", () => {
  it("numbers ISO weeks", () => {
    expect(isoWeekNumber("2026-01-01")).toBe(1);
    expect(isoWeekNumber("2026-11-11")).toBe(46);
  });
});

describe("computeWeeklyStats", () => {
  const entries = [
    { day: "2026-11-09", studiedSeconds: 2 * HOUR },
    { day: "2026-11-10", studiedSeconds: 2 * HOUR },
    { day: "2026-11-03", studiedSeconds: 2 * HOUR },
  ];

  it("sums the Monday-start week against the goal and compares with last week", () => {
    const stats = computeWeeklyStats(entries, NOW, 8 * 60);

    expect(stats).toMatchObject({
      hoursLogged: 4,
      hoursTarget: 8,
      progressPercent: 50,
      goalDeltaPercent: 100,
    });
  });

  it("starts the week on Monday in Vietnam time, not UTC", () => {
    const sundayNightUtc = new Date("2026-11-08T18:00:00Z");

    const stats = computeWeeklyStats(
      [{ day: "2026-11-09", studiedSeconds: HOUR }],
      sundayNightUtc,
      60,
    );

    expect(stats.weekSeconds).toBe(HOUR);
  });

  it("never reports a negative delta and handles a zero goal", () => {
    const stats = computeWeeklyStats([{ day: "2026-11-03", studiedSeconds: HOUR }], NOW, 0);

    expect(stats.progressPercent).toBe(0);
    expect(stats.goalDeltaPercent).toBe(0);
  });
});

describe("badgeHint", () => {
  it("states the remaining hours", () => {
    expect(badgeHint(960, 14.5 * HOUR)).toContain("1.5 giờ");
  });

  it("congratulates when the goal is met", () => {
    expect(badgeHint(60, 2 * HOUR)).toContain("đã đủ");
  });
});
