import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import {
  DISPLAY_TIME_ZONE,
  addDaysToVnDay,
  addVnDays,
  formatRelativeAgo,
  formatRelativeDayLabel,
  formatVnClock,
  getVnCalendarDay,
  startOfVnDay,
  startOfVnWeek,
} from "./date";

// 2026-11-11 is a Wednesday.
const LATE_UTC = new Date("2026-11-11T23:00:00.000Z"); // 06:00 on 12/11 in VN
const VN_MIDNIGHT = new Date("2026-11-11T17:00:00.000Z"); // 00:00 on 12/11 in VN
const JUST_BEFORE_VN_MIDNIGHT = new Date("2026-11-11T16:59:59.999Z");

describe("calendar day helpers", () => {
  beforeEach(() => {
    vi.useFakeTimers();
    vi.setSystemTime(LATE_UTC);
  });
  afterEach(() => vi.useRealTimers());

  it("exposes the display time zone", () => {
    expect(DISPLAY_TIME_ZONE).toBe("Asia/Ho_Chi_Minh");
  });

  it("returns the next VN day for 23:00 UTC", () => {
    expect(getVnCalendarDay(new Date())).toBe("2026-11-12");
  });

  it("switches VN day exactly at 17:00 UTC", () => {
    expect(getVnCalendarDay(JUST_BEFORE_VN_MIDNIGHT)).toBe("2026-11-11");
    expect(getVnCalendarDay(VN_MIDNIGHT)).toBe("2026-11-12");
  });

  it("starts the VN day at 17:00 UTC of the previous day", () => {
    expect(startOfVnDay(LATE_UTC).toISOString()).toBe("2026-11-11T17:00:00.000Z");
    expect(startOfVnDay(VN_MIDNIGHT).toISOString()).toBe("2026-11-11T17:00:00.000Z");
    expect(startOfVnDay(JUST_BEFORE_VN_MIDNIGHT).toISOString()).toBe("2026-11-10T17:00:00.000Z");
  });

  it("starts the week on Monday 00:00 VN", () => {
    // 12/11 VN is a Thursday, so the week began Monday 09/11 00:00 VN.
    expect(startOfVnWeek(LATE_UTC).toISOString()).toBe("2026-11-08T17:00:00.000Z");
  });

  it("treats Sunday as the last day of the week", () => {
    const sundayVn = new Date("2026-11-15T10:00:00.000Z");
    expect(startOfVnWeek(sundayVn).toISOString()).toBe("2026-11-08T17:00:00.000Z");
  });

  it("starts a new week at Monday VN midnight", () => {
    const mondayVn = new Date("2026-11-08T17:00:00.000Z");
    expect(startOfVnWeek(mondayVn).toISOString()).toBe("2026-11-08T17:00:00.000Z");
    expect(startOfVnWeek(new Date(mondayVn.getTime() - 1)).toISOString()).toBe(
      "2026-11-01T17:00:00.000Z",
    );
  });

  it("adds whole days", () => {
    expect(addVnDays(VN_MIDNIGHT, 7).toISOString()).toBe("2026-11-18T17:00:00.000Z");
    expect(addVnDays(VN_MIDNIGHT, -1).toISOString()).toBe("2026-11-10T17:00:00.000Z");
  });

  it("adds days to a calendar day string across month ends", () => {
    expect(addDaysToVnDay("2026-11-30", 1)).toBe("2026-12-01");
    expect(addDaysToVnDay("2026-03-01", -1)).toBe("2026-02-28");
  });

  it("formats the VN clock", () => {
    expect(formatVnClock(LATE_UTC)).toBe("06:00");
    expect(formatVnClock(VN_MIDNIGHT)).toBe("00:00");
  });
});

describe("formatRelativeDayLabel", () => {
  const now = new Date("2026-11-11T23:00:00.000Z"); // 12/11 06:00 VN

  it("labels today in VN time even when UTC is still the previous day", () => {
    expect(formatRelativeDayLabel(new Date("2026-11-11T17:30:00.000Z"), now)).toBe("Hôm nay 00:30");
  });

  it("labels yesterday", () => {
    expect(formatRelativeDayLabel(new Date("2026-11-11T13:15:00.000Z"), now)).toBe("Hôm qua 20:15");
  });

  it("uses dd/MM for older days", () => {
    expect(formatRelativeDayLabel(new Date("2026-11-13T00:00:00.000Z"), now)).toBe("13/11 07:00");
    expect(formatRelativeDayLabel(new Date("2026-11-07T00:00:00.000Z"), now)).toBe("07/11 07:00");
  });
});

describe("formatRelativeAgo", () => {
  const now = new Date("2026-11-11T23:00:00.000Z");

  it("reports hours", () => {
    expect(formatRelativeAgo(new Date(now.getTime() - 7 * 3_600_000), now)).toBe("7 giờ trước");
  });

  it("reports days", () => {
    expect(formatRelativeAgo(new Date(now.getTime() - 2 * 86_400_000 - 1), now)).toBe(
      "2 ngày trước",
    );
  });

  it("reports minutes and just now", () => {
    expect(formatRelativeAgo(new Date(now.getTime() - 5 * 60_000), now)).toBe("5 phút trước");
    expect(formatRelativeAgo(new Date(now.getTime() - 10_000), now)).toBe("Vừa xong");
  });

  it("never reports the future as negative", () => {
    expect(formatRelativeAgo(new Date(now.getTime() + 5_000), now)).toBe("Vừa xong");
  });
});
