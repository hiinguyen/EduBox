import { describe, expect, it } from "vitest";
import {
  formatDeadline,
  formatDurationLabel,
  formatSubmittedAt,
  formatSubmittedTime,
  toShortName,
} from "./labels";

// 2026-11-11 07:22:18 UTC is 14:22:18 in Asia/Ho_Chi_Minh.
const SUBMITTED = new Date("2026-11-11T07:22:18Z");

describe("toShortName", () => {
  it("keeps the honorific and the given name", () => {
    expect(toShortName("Cô Nguyễn Thu Hà")).toBe("cô Hà");
    expect(toShortName("Thầy Trần Quang Minh")).toBe("thầy Minh");
  });

  it("returns a single word unchanged", () => {
    expect(toShortName("Hà")).toBe("Hà");
  });
});

describe("formatDurationLabel", () => {
  it("splits seconds into minutes and zero-padded seconds", () => {
    expect(formatDurationLabel(2295)).toBe("38 phút 15 giây");
    expect(formatDurationLabel(2700)).toBe("45 phút 00 giây");
    expect(formatDurationLabel(-5)).toBe("0 phút 00 giây");
  });
});

describe("formatSubmittedAt", () => {
  it("marks a same-day submission as today in the display time zone", () => {
    const now = new Date("2026-11-11T10:00:00Z");

    expect(formatSubmittedAt(SUBMITTED, now)).toBe("14:22 Hôm nay");
  });

  it("shows the date for an earlier day", () => {
    const now = new Date("2026-11-13T10:00:00Z");

    expect(formatSubmittedAt(SUBMITTED, now)).toBe("14:22 11/11");
  });

  it("uses the display time zone for the day boundary", () => {
    const lateNight = new Date("2026-11-11T16:30:00Z");
    const nextLocalDay = new Date("2026-11-11T17:30:00Z");

    expect(formatSubmittedAt(lateNight, nextLocalDay)).toBe("23:30 11/11");
  });
});

describe("formatSubmittedTime", () => {
  it("includes seconds", () => {
    expect(formatSubmittedTime(SUBMITTED)).toBe("14:22:18");
  });
});

describe("formatDeadline", () => {
  it("omits the date for a deadline today", () => {
    expect(formatDeadline(new Date("2026-11-11T11:00:00Z"), SUBMITTED)).toBe("18:00");
  });

  it("includes the date for another day", () => {
    expect(formatDeadline(new Date("2026-11-12T11:00:00Z"), SUBMITTED)).toBe("18:00 12/11");
  });
});
