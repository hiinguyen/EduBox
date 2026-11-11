import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { currentWeekRange, lookbackStart, studyDayKey, vnDayToDate } from "./study-window";

const utcDay = (day: string) => new Date(`${day}T00:00:00.000Z`);

describe("currentWeekRange", () => {
  it("starts on the Monday of the Vietnam week and ends today", () => {
    // Wednesday 11/11/2026 16:00 VN.
    const range = currentWeekRange(new Date("2026-11-11T09:00:00Z"));

    expect(range).toEqual({ from: utcDay("2026-11-09"), to: utcDay("2026-11-11") });
  });

  it("treats Sunday as the last day of the week", () => {
    const range = currentWeekRange(new Date("2026-11-15T09:00:00Z"));

    expect(range.from).toEqual(utcDay("2026-11-09"));
    expect(range.to).toEqual(utcDay("2026-11-15"));
  });

  it("rolls into the new week at Vietnam midnight (17:00 UTC on Sunday)", () => {
    const beforeMidnight = currentWeekRange(new Date("2026-11-15T16:59:59Z"));
    const atMidnight = currentWeekRange(new Date("2026-11-15T17:00:00Z"));

    expect(beforeMidnight.from).toEqual(utcDay("2026-11-09"));
    expect(atMidnight).toEqual({ from: utcDay("2026-11-16"), to: utcDay("2026-11-16") });
  });

  it("uses Monday morning in Vietnam when it is still Sunday 23:00 UTC", () => {
    const range = currentWeekRange(new Date("2026-11-15T23:00:00Z"));

    expect(range).toEqual({ from: utcDay("2026-11-16"), to: utcDay("2026-11-16") });
  });
});

describe("lookbackStart", () => {
  it("goes back whole Vietnam days", () => {
    expect(lookbackStart(new Date("2026-11-11T23:00:00Z"), 60)).toEqual(utcDay("2026-09-13"));
    expect(lookbackStart(new Date("2026-11-11T17:00:00Z"), 1)).toEqual(utcDay("2026-11-11"));
  });
});

describe("day keys", () => {
  it("round-trips a calendar day", () => {
    expect(studyDayKey(vnDayToDate("2026-11-11"))).toBe("2026-11-11");
  });
});

describe("with a faked clock", () => {
  beforeEach(() => vi.useFakeTimers());
  afterEach(() => vi.useRealTimers());

  it("does not depend on the process time zone for the current day", () => {
    vi.setSystemTime(new Date("2026-11-11T23:00:00Z"));

    expect(currentWeekRange(new Date()).to).toEqual(utcDay("2026-11-12"));
  });
});
