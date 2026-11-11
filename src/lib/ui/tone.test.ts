import { describe, expect, it } from "vitest";
import { TONES, TONE_BAR_CLASS, TONE_BG_CLASS, TONE_RING_CLASS, TONE_TEXT_CLASS } from "./tone";

describe("tone class maps", () => {
  it("defines every tone in every map", () => {
    for (const map of [TONE_TEXT_CLASS, TONE_BG_CLASS, TONE_BAR_CLASS, TONE_RING_CLASS]) {
      expect(Object.keys(map).sort()).toEqual([...TONES].sort());
    }
  });

  it("uses the tone name in the primary text class", () => {
    expect(TONE_TEXT_CLASS.primary).toBe("text-primary");
  });

  it("maps the error tone to the error tokens", () => {
    expect(TONE_TEXT_CLASS.error).toBe("text-error");
    expect(TONE_BG_CLASS.error).toBe("bg-error-container text-on-error-container");
    expect(TONE_BAR_CLASS.error).toBe("bg-error");
    expect(TONE_RING_CLASS.error).toBe("ring-error");
  });
});
