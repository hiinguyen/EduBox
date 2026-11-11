import { describe, expect, it } from "vitest";
import { combineAverages, computeCompletionRate } from "./stats";

describe("computeCompletionRate", () => {
  it("returns null when nothing was assigned", () => {
    expect(computeCompletionRate(0, 0)).toBeNull();
    expect(computeCompletionRate(5, 0)).toBeNull();
  });

  it("divides submitted work by assigned work", () => {
    expect(computeCompletionRate(67, 95)).toEqual({ percent: 70.5, submitted: 67, expected: 95 });
  });

  it("caps the rate at 100 percent", () => {
    expect(computeCompletionRate(12, 10)?.percent).toBe(100);
  });
});

describe("combineAverages", () => {
  it("adds the two parts and returns null when either is missing", () => {
    expect(combineAverages(5.5, 2.25)).toBe(7.75);
    expect(combineAverages(null, 2)).toBeNull();
    expect(combineAverages(5, null)).toBeNull();
  });
});
