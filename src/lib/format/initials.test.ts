import { describe, expect, it } from "vitest";
import { getInitials } from "./initials";

describe("getInitials", () => {
  it("returns the first letters of the last two words by default", () => {
    expect(getInitials("Nguyễn Minh Anh", 2)).toBe("MA");
  });

  it("returns a single letter from the given name when maxLetters is 1", () => {
    expect(getInitials("Trần Thị bích", 1)).toBe("B");
  });

  it("keeps Vietnamese diacritics and uppercases them", () => {
    expect(getInitials("đỗ Ánh", 2)).toBe("ĐÁ");
  });

  it("returns fewer letters when the name has fewer words", () => {
    expect(getInitials("Linh", 2)).toBe("L");
  });

  it("ignores extra whitespace", () => {
    expect(getInitials("  Lê   Hoa  ", 2)).toBe("LH");
  });

  it("returns an empty string for a blank name", () => {
    expect(getInitials("   ", 2)).toBe("");
  });

  it("keeps honorifics as words unless told to skip them", () => {
    expect(getInitials("Cô Lan", 2)).toBe("CL");
  });

  it("skips the Cô and Thầy honorifics when requested", () => {
    expect(getInitials("Cô Phạm Lan", 2, { shouldSkipHonorific: true })).toBe("PL");
    expect(getInitials("Thầy Trần Đức Dũng", 2, { shouldSkipHonorific: true })).toBe("ĐD");
    expect(getInitials("Cô Lan", 1, { shouldSkipHonorific: true })).toBe("L");
  });

  it("does not treat a name that merely starts with the letters as an honorific", () => {
    expect(getInitials("Cổ Lan", 2, { shouldSkipHonorific: true })).toBe("CL");
  });
});
