import { describe, expect, it } from "vitest";
import { getScreen, SCREENS } from "./screens";

describe("SCREENS", () => {
  it("has a unique href for each of the four Stitch screens", () => {
    expect(SCREENS).toHaveLength(4);
    expect(new Set(SCREENS.map((s) => s.href)).size).toBe(4);
  });

  it("lists the online exam screen at /thi-truc-tuyen", () => {
    expect(SCREENS.map((s) => s.href)).toContain("/thi-truc-tuyen");
  });

  it("finds a screen by its route", () => {
    expect(getScreen("/thi-truc-tuyen").title).toBe("Làm bài & Thi trực tuyến");
  });
});
