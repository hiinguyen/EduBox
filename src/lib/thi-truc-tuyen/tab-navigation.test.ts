import { describe, expect, it } from "vitest";
import { getNextTabIndex } from "./tab-navigation";

describe("getNextTabIndex", () => {
  it("moves right and wraps from the last tab to the first", () => {
    expect(getNextTabIndex("ArrowRight", 0, 2)).toBe(1);
    expect(getNextTabIndex("ArrowRight", 1, 2)).toBe(0);
  });

  it("moves left and wraps from the first tab to the last", () => {
    expect(getNextTabIndex("ArrowLeft", 1, 2)).toBe(0);
    expect(getNextTabIndex("ArrowLeft", 0, 2)).toBe(1);
  });

  it("jumps to the first and last tab with Home and End", () => {
    expect(getNextTabIndex("Home", 1, 3)).toBe(0);
    expect(getNextTabIndex("End", 0, 3)).toBe(2);
  });

  it("ignores other keys", () => {
    expect(getNextTabIndex("Enter", 0, 2)).toBeNull();
  });

  it("returns null when there are no tabs", () => {
    expect(getNextTabIndex("ArrowRight", 0, 0)).toBeNull();
  });
});
