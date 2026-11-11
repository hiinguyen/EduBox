import { describe, expect, it } from "vitest";
import { getRemainingAnnouncement, getRemainingMs, isTimeUp } from "./countdown";

const MINUTE = 60_000;

describe("getRemainingMs", () => {
  it("derives remaining time from the absolute end time", () => {
    expect(getRemainingMs(10 * MINUTE, 4 * MINUTE)).toBe(6 * MINUTE);
  });

  it("never returns a negative value once time is up", () => {
    expect(getRemainingMs(MINUTE, 5 * MINUTE)).toBe(0);
  });

  it("gives the same answer after a refresh at the same wall clock time", () => {
    const endsAt = 5_000_000;

    expect(getRemainingMs(endsAt, 4_000_000)).toBe(getRemainingMs(endsAt, 4_000_000));
  });
});

describe("isTimeUp", () => {
  it("is false while time remains", () => {
    expect(isTimeUp(10 * MINUTE, 4 * MINUTE)).toBe(false);
  });

  it("is true exactly at the end time and after it", () => {
    expect(isTimeUp(MINUTE, MINUTE)).toBe(true);
    expect(isTimeUp(MINUTE, 5 * MINUTE)).toBe(true);
  });

  it("is false before the end time has been set", () => {
    expect(isTimeUp(0, 5 * MINUTE)).toBe(false);
  });
});

describe("getRemainingAnnouncement", () => {
  it("announces whole minutes remaining in Vietnamese", () => {
    expect(getRemainingAnnouncement(34 * MINUTE + 15_000)).toBe("Còn 35 phút");
  });

  it("stays identical within the same minute so assistive tech is not spammed", () => {
    expect(getRemainingAnnouncement(34 * MINUTE + 59_000)).toBe(
      getRemainingAnnouncement(34 * MINUTE + 1_000),
    );
  });

  it("announces when time is up", () => {
    expect(getRemainingAnnouncement(0)).toBe("Đã hết giờ làm bài");
  });
});
