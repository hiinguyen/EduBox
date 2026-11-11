import { describe, expect, it } from "vitest";
import { clearDraft, readDraft, writeDraft } from "./draft-storage";
import type { StoredExamState } from "./exam-state";
import type { Question } from "./types";

const QUESTIONS: readonly Question[] = [
  {
    id: "q-1",
    number: 1,
    prompt: [],
    levelLabel: "Nhận biết",
    points: 0.4,
    options: [{ id: "A", label: "A", text: "A" }],
  },
];

const ATTEMPT_ID = "attempt-1";

const DRAFT: StoredExamState = {
  answers: { "q-1": "A" },
  notes: {},
  flaggedIds: [],
  currentIndex: 0,
  touchedAt: {},
  savedAt: 5_000,
};

function memoryStorage(): Storage {
  const data = new Map<string, string>();
  return {
    get length() {
      return data.size;
    },
    clear: () => data.clear(),
    getItem: (key) => data.get(key) ?? null,
    key: (index) => [...data.keys()][index] ?? null,
    removeItem: (key) => void data.delete(key),
    setItem: (key, value) => void data.set(key, value),
  };
}

function brokenStorage(): Storage {
  const fail = () => {
    throw new DOMException("denied", "SecurityError");
  };
  return { ...memoryStorage(), getItem: fail, setItem: fail };
}

describe("draft storage", () => {
  it("reads back a written draft", () => {
    const storage = memoryStorage();

    writeDraft(storage, ATTEMPT_ID, DRAFT);

    expect(readDraft(storage, ATTEMPT_ID, QUESTIONS)).toEqual(DRAFT);
  });

  it("returns null when nothing was stored", () => {
    expect(readDraft(memoryStorage(), ATTEMPT_ID, QUESTIONS)).toBeNull();
  });

  it("returns null when storage throws on read", () => {
    expect(readDraft(brokenStorage(), ATTEMPT_ID, QUESTIONS)).toBeNull();
  });

  it("reports failure instead of throwing when storage throws on write", () => {
    expect(writeDraft(brokenStorage(), ATTEMPT_ID, DRAFT)).toBe(false);
  });

  it("reports failure when browser storage is unavailable", () => {
    expect(writeDraft(null, ATTEMPT_ID, DRAFT)).toBe(false);
    expect(readDraft(null, ATTEMPT_ID, QUESTIONS)).toBeNull();
  });

  it("reports success when the draft was written", () => {
    expect(writeDraft(memoryStorage(), ATTEMPT_ID, DRAFT)).toBe(true);
  });
});

describe("clearDraft", () => {
  it("removes a stored draft", () => {
    const storage = memoryStorage();
    writeDraft(storage, ATTEMPT_ID, DRAFT);

    clearDraft(storage, ATTEMPT_ID);

    expect(readDraft(storage, ATTEMPT_ID, QUESTIONS)).toBeNull();
  });

  it("does not throw when storage is unavailable", () => {
    expect(() => clearDraft(null, ATTEMPT_ID)).not.toThrow();
  });

  it("ignores a draft written for another attempt", () => {
    const storage = memoryStorage();
    writeDraft(storage, "attempt-2", DRAFT);

    expect(readDraft(storage, ATTEMPT_ID, QUESTIONS)).toBeNull();
  });
});
