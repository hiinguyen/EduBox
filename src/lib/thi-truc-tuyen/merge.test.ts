import { describe, expect, it } from "vitest";
import { mergeProgress } from "./merge";
import type { LocalProgress, ServerProgress } from "./merge";

const IDS = ["q1", "q2", "q3"];

const SERVER: ServerProgress = {
  answers: {
    q1: { optionId: "a", isFlagged: false, answeredAt: 1_000 },
    q2: { optionId: "b", isFlagged: true, answeredAt: 5_000 },
  },
  currentIndex: 1,
  updatedAt: 5_000,
};

function local(overrides: Partial<LocalProgress>): LocalProgress {
  return {
    answers: {},
    flaggedIds: [],
    touchedAt: {},
    currentIndex: 0,
    savedAt: 0,
    ...overrides,
  };
}

describe("mergeProgress", () => {
  it("uses the server alone when there is no local draft", () => {
    const merged = mergeProgress(SERVER, null, IDS);

    expect(merged.answers).toEqual({ q1: "a", q2: "b" });
    expect(merged.flaggedIds).toEqual(["q2"]);
    expect(merged.currentIndex).toBe(1);
  });

  it("uses the local draft alone when the server has nothing", () => {
    const draft = local({
      answers: { q3: "d" },
      touchedAt: { q3: 2_000 },
      currentIndex: 2,
      savedAt: 2_000,
    });

    const merged = mergeProgress({ answers: {}, currentIndex: 0, updatedAt: 0 }, draft, IDS);

    expect(merged.answers).toEqual({ q3: "d" });
    expect(merged.currentIndex).toBe(2);
  });

  it("keeps the newer side for each question independently", () => {
    const draft = local({
      answers: { q1: "c", q2: "a" },
      touchedAt: { q1: 3_000, q2: 4_000 },
      savedAt: 4_000,
    });

    const merged = mergeProgress(SERVER, draft, IDS);

    expect(merged.answers).toEqual({ q1: "c", q2: "b" });
    expect(merged.touchedAt).toEqual({ q1: 3_000, q2: 5_000 });
  });

  it("takes the flag together with the winning answer", () => {
    const draft = local({
      answers: { q2: "a" },
      flaggedIds: [],
      touchedAt: { q2: 9_000 },
      savedAt: 9_000,
    });

    const merged = mergeProgress(SERVER, draft, IDS);

    expect(merged.answers.q2).toBe("a");
    expect(merged.flaggedIds).toEqual([]);
  });

  it("lets the server win a tie", () => {
    const draft = local({ answers: { q1: "c" }, touchedAt: { q1: 1_000 }, savedAt: 1_000 });

    expect(mergeProgress(SERVER, draft, IDS).answers.q1).toBe("a");
  });

  it("gives the same result however many times it is applied", () => {
    const draft = local({ answers: { q1: "c" }, touchedAt: { q1: 3_000 }, savedAt: 3_000 });

    const once = mergeProgress(SERVER, draft, IDS);
    const twice = mergeProgress(SERVER, { ...draft, ...once, savedAt: 3_000 }, IDS);

    expect(twice.answers).toEqual(once.answers);
  });

  it("ignores question ids that are not part of the exam", () => {
    const draft = local({ answers: { other: "a" }, touchedAt: { other: 9_000 } });

    expect(mergeProgress(SERVER, draft, IDS).answers).not.toHaveProperty("other");
  });

  it("restores the position from whichever side saved last", () => {
    const newerLocal = local({ currentIndex: 2, savedAt: 6_000 });
    const olderLocal = local({ currentIndex: 2, savedAt: 4_000 });

    expect(mergeProgress(SERVER, newerLocal, IDS).currentIndex).toBe(2);
    expect(mergeProgress(SERVER, olderLocal, IDS).currentIndex).toBe(1);
  });

  it("treats a local entry without a timestamp as saved at the draft time", () => {
    const draft = local({ answers: { q1: "c" }, savedAt: 7_000 });

    expect(mergeProgress(SERVER, draft, IDS).answers.q1).toBe("c");
  });
});
