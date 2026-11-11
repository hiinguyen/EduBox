import { describe, expect, it } from "vitest";
import {
  decideGradeEffects,
  formatScore,
  formatScoreOutOf,
  getInitialEssayScore,
  needsReview,
  toScoreOutOf10,
} from "./grading";

describe("formatScore", () => {
  it("renders one decimal place", () => {
    expect(formatScore(6)).toBe("6.0");
    expect(formatScoreOutOf(3.5, 4)).toBe("3.5 / 4.0");
  });

  it("keeps the quarter step visible", () => {
    expect(formatScore(3.25)).toBe("3.25");
    expect(formatScore(3.75)).toBe("3.75");
  });
});

describe("needsReview", () => {
  it("is true only while the essay has no score", () => {
    expect(needsReview({ essayScore: null })).toBe(true);
    expect(needsReview({ essayScore: 0 })).toBe(false);
  });
});

describe("getInitialEssayScore", () => {
  it("uses the saved score first, then the AI hint, then empty", () => {
    expect(getInitialEssayScore(2, 3.25)).toBe("2");
    expect(getInitialEssayScore(null, 3.25)).toBe("3.25");
    expect(getInitialEssayScore(null, undefined)).toBe("");
  });
});

describe("decideGradeEffects", () => {
  const NOTIFIED_AT = new Date("2026-11-10T10:00:00Z");

  it("records and notifies a first grade when the box is ticked", () => {
    expect(decideGradeEffects(null, { essayScore: 3, shouldNotifyParent: true })).toEqual({
      hasScoreChanged: true,
      shouldNotifyParents: true,
    });
  });

  it("never notifies when the box is not ticked", () => {
    const prior = { essayScore: 2, notifiedAt: null };

    expect(decideGradeEffects(prior, { essayScore: 3, shouldNotifyParent: false })).toEqual({
      hasScoreChanged: true,
      shouldNotifyParents: false,
    });
  });

  it("does not repeat anything when the same score is re-saved after a notice", () => {
    const prior = { essayScore: 3, notifiedAt: NOTIFIED_AT };

    expect(decideGradeEffects(prior, { essayScore: 3, shouldNotifyParent: true })).toEqual({
      hasScoreChanged: false,
      shouldNotifyParents: false,
    });
  });

  it("notifies an unchanged score that parents were never told about", () => {
    const prior = { essayScore: 3, notifiedAt: null };

    expect(decideGradeEffects(prior, { essayScore: 3, shouldNotifyParent: true })).toEqual({
      hasScoreChanged: false,
      shouldNotifyParents: true,
    });
  });

  it("notifies again when the score changed after a notice", () => {
    const prior = { essayScore: 3, notifiedAt: NOTIFIED_AT };

    expect(decideGradeEffects(prior, { essayScore: 3.5, shouldNotifyParent: true })).toEqual({
      hasScoreChanged: true,
      shouldNotifyParents: true,
    });
  });
});

describe("toScoreOutOf10", () => {
  it("normalizes the total to a ten point scale", () => {
    expect(toScoreOutOf10(8.5, 10)).toBe(8.5);
    expect(toScoreOutOf10(4.5, 5)).toBe(9);
  });

  it("returns null without a positive maximum", () => {
    expect(toScoreOutOf10(3, 0)).toBeNull();
    expect(toScoreOutOf10(3, -1)).toBeNull();
  });
});
