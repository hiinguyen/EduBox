import { describe, expect, it } from "vitest";
import { roundTo } from "./number";

describe("roundTo", () => {
  it("rounds to the requested decimals", () => {
    expect(roundTo(8.456, 1)).toBe(8.5);
    expect(roundTo(8.454, 2)).toBe(8.45);
  });

  it("avoids binary floating point drift", () => {
    expect(roundTo(1.005, 2)).toBe(1.01);
  });

  it("rounds negatives away from zero", () => {
    expect(roundTo(-2.5, 0)).toBe(-3);
  });

  it("returns whole numbers unchanged and passes non-finite values through", () => {
    expect(roundTo(7, 2)).toBe(7);
    expect(roundTo(Number.NaN, 1)).toBeNaN();
  });
});
