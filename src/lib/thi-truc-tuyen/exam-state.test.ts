import { describe, expect, it } from "vitest";
import { createInitialState, examReducer, resolveInitialState } from "./exam-state";

const QUESTION_COUNT = 5;
const NOW = 1_000;

function freshState() {
  return createInitialState({ questionCount: QUESTION_COUNT, endsAt: 99_000, now: NOW });
}

describe("examReducer", () => {
  it("records the selected option for a question", () => {
    const state = examReducer(freshState(), {
      type: "select",
      questionId: "q-2",
      optionId: "B",
      at: 2_000,
    });

    expect(state.answers).toEqual({ "q-2": "B" });
    expect(state.savedAt).toBe(2_000);
  });

  it("replaces the previous answer when another option is selected", () => {
    const first = examReducer(freshState(), {
      type: "select",
      questionId: "q-2",
      optionId: "B",
      at: 2_000,
    });
    const second = examReducer(first, {
      type: "select",
      questionId: "q-2",
      optionId: "C",
      at: 3_000,
    });

    expect(second.answers["q-2"]).toBe("C");
  });

  it("flags then unflags a question", () => {
    const flagged = examReducer(freshState(), { type: "toggleFlag", questionId: "q-3", at: 2_000 });
    const unflagged = examReducer(flagged, { type: "toggleFlag", questionId: "q-3", at: 3_000 });

    expect(flagged.flaggedIds).toEqual(["q-3"]);
    expect(unflagged.flaggedIds).toEqual([]);
  });

  it("moves to the next and previous question within bounds", () => {
    const next = examReducer(freshState(), { type: "next", at: 2_000 });
    const back = examReducer(next, { type: "previous", at: 3_000 });
    const clamped = examReducer(back, { type: "previous", at: 4_000 });

    expect(next.currentIndex).toBe(1);
    expect(back.currentIndex).toBe(0);
    expect(clamped.currentIndex).toBe(0);
  });

  it("does not move past the last question", () => {
    const last = examReducer(freshState(), { type: "goTo", index: 4, at: 2_000 });
    const clamped = examReducer(last, { type: "next", at: 3_000 });

    expect(clamped.currentIndex).toBe(4);
  });

  it("ignores navigation to an index outside the exam", () => {
    const state = examReducer(freshState(), { type: "goTo", index: 99, at: 2_000 });

    expect(state.currentIndex).toBe(0);
  });

  it("does not mutate the previous state", () => {
    const before = freshState();
    examReducer(before, { type: "select", questionId: "q-1", optionId: "A", at: 2_000 });

    expect(before.answers).toEqual({});
  });

  it("stores a written note per question", () => {
    const state = examReducer(freshState(), {
      type: "setNote",
      questionId: "q-2",
      note: "g'(x) = 0",
      at: 2_000,
    });

    expect(state.notes).toEqual({ "q-2": "g'(x) = 0" });
  });

  it("updates the saved time on a manual save without changing answers", () => {
    const state = examReducer(freshState(), { type: "save", at: 9_000 });

    expect(state.savedAt).toBe(9_000);
    expect(state.answers).toEqual({});
  });
});

describe("examReducer after the deadline", () => {
  const AFTER_DEADLINE = 99_000;

  it("ignores answers, notes, flags and navigation once time is up", () => {
    const state = freshState();
    const actions = [
      { type: "select", questionId: "q-1", optionId: "A", at: AFTER_DEADLINE },
      { type: "setNote", questionId: "q-1", note: "x", at: AFTER_DEADLINE },
      { type: "toggleFlag", questionId: "q-1", at: AFTER_DEADLINE },
      { type: "goTo", index: 2, at: AFTER_DEADLINE },
      { type: "next", at: AFTER_DEADLINE },
      { type: "previous", at: AFTER_DEADLINE },
    ] as const;

    for (const action of actions) {
      expect(examReducer(state, action)).toBe(state);
    }
  });

  it("still accepts answers one millisecond before the deadline", () => {
    const state = examReducer(freshState(), {
      type: "select",
      questionId: "q-1",
      optionId: "A",
      at: AFTER_DEADLINE - 1,
    });

    expect(state.answers).toEqual({ "q-1": "A" });
  });
});

describe("resolveInitialState", () => {
  const IDS = ["q-1", "q-2", "q-3"];
  const SERVER = {
    answers: {
      "q-1": { optionId: "A", isFlagged: false, answeredAt: 5_000 },
      "q-2": { optionId: null, isFlagged: true, answeredAt: 5_000 },
    },
    currentIndex: 2,
    updatedAt: 5_000,
  };

  it("restores the server answers and takes the deadline from the server", () => {
    const state = resolveInitialState({
      server: SERVER,
      stored: null,
      questionIds: IDS,
      endsAt: 80_000,
      now: NOW,
    });

    expect(state).toMatchObject({
      answers: { "q-1": "A" },
      flaggedIds: ["q-2"],
      currentIndex: 2,
      endsAt: 80_000,
      questionCount: 3,
    });
  });

  it("lets a newer local change win and keeps local notes", () => {
    const stored = {
      answers: { "q-1": "D" },
      notes: { "q-1": "nháp" },
      flaggedIds: [],
      currentIndex: 0,
      touchedAt: { "q-1": 9_000 },
      savedAt: 9_000,
    };

    const state = resolveInitialState({
      server: SERVER,
      stored,
      questionIds: IDS,
      endsAt: 80_000,
      now: NOW,
    });

    expect(state.answers).toEqual({ "q-1": "D" });
    expect(state.notes).toEqual({ "q-1": "nháp" });
    expect(state.endsAt).toBe(80_000);
  });

  it("clamps a saved position that is outside the exam", () => {
    const state = resolveInitialState({
      server: { ...SERVER, currentIndex: 40 },
      stored: null,
      questionIds: IDS,
      endsAt: 80_000,
      now: NOW,
    });

    expect(state.currentIndex).toBe(2);
  });
});

describe("change times", () => {
  it("records when an answer or a flag last changed", () => {
    const answered = examReducer(freshState(), {
      type: "select",
      questionId: "q-1",
      optionId: "A",
      at: 2_000,
    });
    const flagged = examReducer(answered, { type: "toggleFlag", questionId: "q-1", at: 3_000 });

    expect(answered.touchedAt).toEqual({ "q-1": 2_000 });
    expect(flagged.touchedAt).toEqual({ "q-1": 3_000 });
  });
});
