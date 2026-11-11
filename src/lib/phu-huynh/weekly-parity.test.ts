import { describe, expect, it } from "vitest";
import { computeStreak } from "@/lib/student/streak";
import { getVnCalendarDay } from "@/lib/format/date";
import { computeStreakDays, type StudyDaySample } from "./effort";

const MINUTES_14 = 14 * 60;
const MINUTES_15 = 15 * 60;

function sample(day: string, studiedSeconds: number): StudyDaySample {
  return { day: new Date(`${day}T00:00:00.000Z`), studiedSeconds };
}

const CASES = [
  { name: "23:00 UTC (06:00 next day VN)", now: "2026-11-11T23:00:00Z" },
  { name: "17:00 UTC (00:00 next day VN)", now: "2026-11-11T17:00:00Z" },
  { name: "midday", now: "2026-11-11T05:00:00Z" },
] as const;

const DAYS = [
  sample("2026-11-12", MINUTES_15),
  sample("2026-11-11", MINUTES_15),
  sample("2026-11-10", MINUTES_14),
  sample("2026-11-09", MINUTES_15),
];

describe("streak parity with the student screen", () => {
  it.each(CASES)("gives the shared computeStreak result at $name", ({ now }) => {
    const instant = new Date(now);
    const shared = computeStreak(
      DAYS.map((entry) => ({
        day: entry.day.toISOString().slice(0, 10),
        studiedSeconds: entry.studiedSeconds,
      })),
      getVnCalendarDay(instant),
    );

    expect(computeStreakDays(DAYS, instant)).toBe(shared);
  });

  it("requires the shared minimum: a 14 minute day breaks the streak", () => {
    expect(computeStreakDays(DAYS, new Date("2026-11-11T05:00:00Z"))).toBe(1);
  });
});
