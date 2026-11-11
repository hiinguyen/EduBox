import { describe, expect, it } from "vitest";
import {
  MS_PER_DAY,
  MS_PER_HOUR,
  MS_PER_MINUTE,
  MS_PER_SECOND,
  formatMsClock,
  formatSecondsClock,
  padTwo,
} from "./time";

describe("padTwo", () => {
  it("pads single digits with a leading zero", () => {
    expect(padTwo(5)).toBe("05");
    expect(padTwo(12)).toBe("12");
  });
});

describe("formatSecondsClock", () => {
  it("formats whole seconds as mm:ss", () => {
    expect(formatSecondsClock(125)).toBe("02:05");
  });

  it("floors fractional seconds", () => {
    expect(formatSecondsClock(59.9)).toBe("00:59");
  });

  it("clamps negative values to zero", () => {
    expect(formatSecondsClock(-4)).toBe("00:00");
  });

  it("lets minutes exceed two digits past an hour", () => {
    expect(formatSecondsClock(3_725)).toBe("62:05");
  });
});

describe("formatMsClock", () => {
  it("rounds partial seconds up so the clock never shows zero early", () => {
    expect(formatMsClock(1 * MS_PER_SECOND + 1)).toBe("00:02");
  });

  it("formats whole milliseconds as mm:ss", () => {
    expect(formatMsClock(34 * 60 * MS_PER_SECOND + 15 * MS_PER_SECOND)).toBe("34:15");
  });

  it("clamps negative values to zero", () => {
    expect(formatMsClock(-500)).toBe("00:00");
  });
});

describe("duration constants", () => {
  it("are consistent multiples of each other", () => {
    expect(MS_PER_MINUTE).toBe(60 * MS_PER_SECOND);
    expect(MS_PER_HOUR).toBe(60 * MS_PER_MINUTE);
    expect(MS_PER_DAY).toBe(24 * MS_PER_HOUR);
  });
});
