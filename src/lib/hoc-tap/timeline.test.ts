import { describe, expect, it } from "vitest";
import { percentOf, ringDashOffset } from "./timeline";

describe("percentOf", () => {
  it("returns the share of the total as a percentage", () => {
    expect(percentOf(1104, 2710)).toBeCloseTo(40.74, 1);
  });

  it("clamps values above the total to 100", () => {
    expect(percentOf(500, 100)).toBe(100);
  });

  it("returns 0 when the total is not positive", () => {
    expect(percentOf(10, 0)).toBe(0);
  });
});

describe("ringDashOffset", () => {
  it("leaves the unfilled share of the circumference as the offset", () => {
    expect(ringDashOffset(85, 100)).toBeCloseTo(15, 5);
  });

  it("returns the full circumference at 0 percent", () => {
    expect(ringDashOffset(0, 163.36)).toBeCloseTo(163.36, 5);
  });

  it("clamps percentages above 100 to a zero offset", () => {
    expect(ringDashOffset(140, 100)).toBe(0);
  });
});
