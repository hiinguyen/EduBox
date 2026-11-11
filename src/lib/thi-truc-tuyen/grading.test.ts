import { describe, expect, it } from "vitest";
import { gradeMultipleChoice, isFullyAutoGradable } from "./grading";

const QUESTIONS = [
  { id: "q1", points: 0.4 },
  { id: "q2", points: 0.4 },
  { id: "q3", points: 0.4 },
];
const KEYS = { q1: "a", q2: "b", q3: "c" };

describe("gradeMultipleChoice", () => {
  it("scores every correct answer", () => {
    const result = gradeMultipleChoice({
      questions: QUESTIONS,
      keys: KEYS,
      answers: { q1: "a", q2: "b", q3: "c" },
    });

    expect(result).toEqual({ score: 1.2, correctCount: 3, totalCount: 3 });
  });

  it("scores zero for wrong, null and missing answers", () => {
    const result = gradeMultipleChoice({
      questions: QUESTIONS,
      keys: KEYS,
      answers: { q1: "x", q2: null },
    });

    expect(result).toEqual({ score: 0, correctCount: 0, totalCount: 3 });
  });

  it("removes floating point noise from the sum", () => {
    const result = gradeMultipleChoice({
      questions: QUESTIONS,
      keys: KEYS,
      answers: { q1: "a", q2: "b" },
    });

    expect(result.score).toBe(0.8);
  });

  it("never counts a question without a key", () => {
    const result = gradeMultipleChoice({
      questions: QUESTIONS,
      keys: { q1: "a" },
      answers: { q1: "a", q2: "b" },
    });

    expect(result.correctCount).toBe(1);
  });

  it("returns zero for an empty exam", () => {
    expect(gradeMultipleChoice({ questions: [], keys: {}, answers: {} })).toEqual({
      score: 0,
      correctCount: 0,
      totalCount: 0,
    });
  });
});

describe("isFullyAutoGradable", () => {
  it("is true only without essay score and essay questions", () => {
    expect(isFullyAutoGradable({ essayMaxScore: 0, hasEssayQuestions: false })).toBe(true);
    expect(isFullyAutoGradable({ essayMaxScore: 4, hasEssayQuestions: false })).toBe(false);
    expect(isFullyAutoGradable({ essayMaxScore: 0, hasEssayQuestions: true })).toBe(false);
  });
});
