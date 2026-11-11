import { describe, expect, it } from "vitest";
import {
  DRAFT_VERSION,
  MAX_NOTE_LENGTH,
  getDraftStorageKey,
  isDraftChangedElsewhere,
  parseDraft,
  serializeDraft,
} from "./draft";
import type { Question } from "./types";

function makeQuestion(number: number): Question {
  return {
    id: `q-${number}`,
    number,
    prompt: [],
    levelLabel: "Nhận biết",
    points: 0.4,
    options: ["A", "B", "C", "D"].map((label) => ({ id: label, label, text: label })),
  };
}

const QUESTIONS: readonly Question[] = [1, 2, 3].map(makeQuestion);

const ATTEMPT_ID = "attempt-1";

const DRAFT = {
  answers: { "q-1": "A" },
  notes: { "q-1": "nháp" },
  flaggedIds: ["q-2"],
  currentIndex: 1,
  touchedAt: { "q-1": 110_000 },
  savedAt: 120_000,
} as const;

function rawWith(overrides: Record<string, unknown>): string {
  return JSON.stringify({ version: DRAFT_VERSION, attemptId: ATTEMPT_ID, ...DRAFT, ...overrides });
}

function parse(raw: string | null, questions: readonly Question[] = QUESTIONS) {
  return parseDraft(raw, questions, ATTEMPT_ID);
}

describe("serializeDraft and parseDraft", () => {
  it("round trips a draft", () => {
    expect(parse(serializeDraft(ATTEMPT_ID, DRAFT))).toEqual(DRAFT);
  });

  it("returns null for missing data", () => {
    expect(parse(null)).toBeNull();
  });

  it("returns null for malformed JSON", () => {
    expect(parse("{not json")).toBeNull();
  });

  it("returns null when the shape is invalid", () => {
    expect(parse(JSON.stringify({ version: DRAFT_VERSION, answers: 3 }))).toBeNull();
  });

  it("returns null for a different stored version", () => {
    expect(parse(rawWith({ version: DRAFT_VERSION + 1 }))).toBeNull();
  });

  it("returns null when the exam has no questions", () => {
    expect(parse(serializeDraft(ATTEMPT_ID, DRAFT), [])).toBeNull();
  });
});

describe("parseDraft validation against the exam", () => {
  it("drops answers for unknown questions and keeps the valid ones", () => {
    const raw = rawWith({ answers: { "q-1": "A", "q-99": "B" } });

    expect(parse(raw)?.answers).toEqual({ "q-1": "A" });
  });

  it("drops answers whose option does not belong to that question", () => {
    const raw = rawWith({ answers: { "q-1": "Z", "q-2": "C" } });

    expect(parse(raw)?.answers).toEqual({ "q-2": "C" });
  });

  it("drops flagged ids that are not in the exam and removes duplicates", () => {
    const raw = rawWith({ flaggedIds: ["q-2", "q-99", "q-2", "q-3"] });

    expect(parse(raw)?.flaggedIds).toEqual(["q-2", "q-3"]);
  });

  it("drops notes for unknown questions", () => {
    const raw = rawWith({ notes: { "q-1": "ok", "q-99": "lạ" } });

    expect(parse(raw)?.notes).toEqual({ "q-1": "ok" });
  });

  it("truncates notes longer than the maximum instead of rejecting the draft", () => {
    const raw = rawWith({ notes: { "q-1": "x".repeat(MAX_NOTE_LENGTH + 10) } });

    expect(parse(raw)?.notes["q-1"]).toHaveLength(MAX_NOTE_LENGTH);
  });

  it("clamps a current question outside the exam to the last question", () => {
    expect(parse(rawWith({ currentIndex: 30 }))?.currentIndex).toBe(2);
  });

  it("ignores prototype keys smuggled into answers", () => {
    const raw = `{"version":1,"attemptId":"${ATTEMPT_ID}","answers":{"__proto__":"A","q-1":"B"},"flaggedIds":[],"currentIndex":0,"savedAt":1}`;

    expect(parse(raw)?.answers).toEqual({ "q-1": "B" });
  });
});

describe("parseDraft with older drafts", () => {
  it("defaults notes and change times to empty when a draft has none", () => {
    const raw = JSON.stringify({
      version: DRAFT_VERSION,
      attemptId: ATTEMPT_ID,
      answers: DRAFT.answers,
      flaggedIds: DRAFT.flaggedIds,
      currentIndex: DRAFT.currentIndex,
      savedAt: DRAFT.savedAt,
    });

    expect(parse(raw)?.notes).toEqual({});
    expect(parse(raw)?.touchedAt).toEqual({});
  });
});

describe("draft ownership", () => {
  it("ignores a draft that belongs to another attempt", () => {
    expect(parse(rawWith({ attemptId: "attempt-2" }))).toBeNull();
  });

  it("never persists or restores a deadline", () => {
    const raw = serializeDraft(ATTEMPT_ID, DRAFT);
    const tampered = rawWith({ endsAt: 9_999_999_999_999 });

    expect(raw).not.toContain("endsAt");
    expect(parse(tampered)).not.toHaveProperty("endsAt");
  });

  it("drops change times for unknown questions", () => {
    const raw = rawWith({ touchedAt: { "q-1": 5, "q-99": 6 } });

    expect(parse(raw)?.touchedAt).toEqual({ "q-1": 5 });
  });
});

describe("getDraftStorageKey", () => {
  it("includes the version and the attempt id", () => {
    expect(getDraftStorageKey("attempt-1")).toBe(`edubox:exam-draft:v${DRAFT_VERSION}:attempt-1`);
  });
});

describe("isDraftChangedElsewhere", () => {
  const key = getDraftStorageKey(ATTEMPT_ID);

  it("is true when another tab writes this exam's draft", () => {
    expect(isDraftChangedElsewhere({ key, newValue: "{}" }, ATTEMPT_ID)).toBe(true);
  });

  it("is false for another exam's draft or unrelated keys", () => {
    expect(
      isDraftChangedElsewhere({ key: getDraftStorageKey("attempt-2"), newValue: "{}" }, ATTEMPT_ID),
    ).toBe(false);
    expect(isDraftChangedElsewhere({ key: "other", newValue: "{}" }, ATTEMPT_ID)).toBe(false);
  });

  it("is false when the draft was removed", () => {
    expect(isDraftChangedElsewhere({ key, newValue: null }, ATTEMPT_ID)).toBe(false);
  });
});
