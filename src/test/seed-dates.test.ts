import { describe, expect, it } from "vitest";
import { getVnCalendarDay, startOfVnWeek } from "@/lib/format/date";
import { vnDay, vnWeekStarts } from "../../prisma/seed-lib/dates";
import { SUBJECT_SCORES } from "../../prisma/seed-data/learning";

const MONDAY = 1;
const WEEKS = 6;
const DAYS_PER_WEEK = 7;
const MS_PER_DAY = 24 * 60 * 60 * 1000;
// Instants around the VN date line, a Wednesday, and the Monday boundary.
const SAMPLE_NOW: readonly string[] = [
  "2026-11-11T05:00:00Z",
  "2026-11-11T17:30:00Z",
  "2026-11-08T17:00:00Z",
  "2026-11-08T16:59:59Z",
  "2026-12-31T20:00:00Z",
];

describe("seed dates", () => {
  it.each(SAMPLE_NOW)("makes every week start a VN Monday at %s", (iso) => {
    const weeks = vnWeekStarts(WEEKS, new Date(iso));

    expect(weeks).toHaveLength(WEEKS);
    for (const week of weeks) {
      expect(week.getUTCDay()).toBe(MONDAY);
      expect(week.getUTCHours()).toBe(0);
    }
  });

  it.each(SAMPLE_NOW)(
    "ends with the current VN week and steps back one week at a time at %s",
    (iso) => {
      const now = new Date(iso);
      const weeks = vnWeekStarts(WEEKS, now);
      const currentMonday = new Date(`${getVnCalendarDay(startOfVnWeek(now))}T00:00:00.000Z`);

      expect(weeks[WEEKS - 1]).toEqual(currentMonday);
      for (let index = 1; index < weeks.length; index += 1) {
        const gap = (weeks[index]?.getTime() ?? 0) - (weeks[index - 1]?.getTime() ?? 0);
        expect(gap).toBe(DAYS_PER_WEEK * MS_PER_DAY);
      }
    },
  );

  it("uses the VN calendar day, not the process day, for StudyDay", () => {
    const lateUtcEvening = new Date("2026-11-11T20:00:00Z");

    expect(vnDay(0, lateUtcEvening)).toEqual(new Date("2026-11-12T00:00:00.000Z"));
    expect(vnDay(-2, lateUtcEvening)).toEqual(new Date("2026-11-10T00:00:00.000Z"));
  });

  it("has exactly one score per seeded week for every subject", () => {
    for (const { scores } of SUBJECT_SCORES) {
      expect(scores).toHaveLength(WEEKS);
    }
  });
});
