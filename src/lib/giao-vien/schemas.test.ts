import { describe, expect, it } from "vitest";
import { MAX_FEEDBACK_LENGTH } from "./constants";
import { gradeInputSchema, isScoreWithinMax, parseAiSuggestion } from "./schemas";

const VALID = { submissionId: "s1", essayScore: 3.25, feedback: "Tốt", shouldNotifyParent: false };

describe("gradeInputSchema", () => {
  it("accepts a valid grade and trims the feedback", () => {
    const result = gradeInputSchema.safeParse({ ...VALID, feedback: "  Tốt  " });

    expect(result.success && result.data.feedback).toBe("Tốt");
  });

  it("accepts an empty feedback", () => {
    expect(gradeInputSchema.safeParse({ ...VALID, feedback: "" }).success).toBe(true);
  });

  it.each([Number.NaN, Number.POSITIVE_INFINITY, Number.NEGATIVE_INFINITY, -0.25, 3.1])(
    "rejects essayScore %s",
    (essayScore) => {
      expect(gradeInputSchema.safeParse({ ...VALID, essayScore }).success).toBe(false);
    },
  );

  it("rejects a string score, a missing id and an over-long feedback", () => {
    expect(gradeInputSchema.safeParse({ ...VALID, essayScore: "3" }).success).toBe(false);
    expect(gradeInputSchema.safeParse({ ...VALID, submissionId: "" }).success).toBe(false);
    const feedback = "x".repeat(MAX_FEEDBACK_LENGTH + 1);
    expect(gradeInputSchema.safeParse({ ...VALID, feedback }).success).toBe(false);
  });

  it("rejects a non-boolean notify flag", () => {
    expect(gradeInputSchema.safeParse({ ...VALID, shouldNotifyParent: "yes" }).success).toBe(false);
  });
});

describe("isScoreWithinMax", () => {
  it("accepts the bounds and rejects values outside or non-finite", () => {
    expect(isScoreWithinMax(0, 4)).toBe(true);
    expect(isScoreWithinMax(4, 4)).toBe(true);
    expect(isScoreWithinMax(4.25, 4)).toBe(false);
    expect(isScoreWithinMax(Number.NaN, 4)).toBe(false);
    expect(isScoreWithinMax(Number.POSITIVE_INFINITY, 4)).toBe(false);
  });
});

describe("parseAiSuggestion", () => {
  it("returns the suggestion when it matches the shape", () => {
    const value = { comment: "c", suggestedScore: 3, feedbackDraft: "f" };

    expect(parseAiSuggestion(value)).toEqual(value);
  });

  it("returns null for null, partial or wrong-typed JSON", () => {
    expect(parseAiSuggestion(null)).toBeNull();
    expect(parseAiSuggestion({ comment: "c" })).toBeNull();
    expect(parseAiSuggestion({ comment: "c", suggestedScore: "3", feedbackDraft: "f" })).toBeNull();
  });
});
