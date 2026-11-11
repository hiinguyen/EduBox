import { describe, expect, it } from "vitest";
import { clampPercent } from "./percent";

describe("clampPercent", () => {
  it("returns values inside the range unchanged", () => {
    expect(clampPercent(42.5)).toBe(42.5);
  });

  it("clamps below zero and above one hundred", () => {
    expect(clampPercent(-3)).toBe(0);
    expect(clampPercent(140)).toBe(100);
  });

  it("returns zero for non-finite input", () => {
    expect(clampPercent(Number.NaN)).toBe(0);
    expect(clampPercent(Number.POSITIVE_INFINITY)).toBe(0);
  });
});
