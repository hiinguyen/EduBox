import { describe, expect, it } from "vitest";
import { getProgress, getQuestionStatus } from "./progress";

const IDS = ["q-1", "q-2", "q-3", "q-4"] as const;

describe("getProgress", () => {
  it("counts answered, unanswered and flagged questions", () => {
    const progress = getProgress(IDS, { "q-1": "A", "q-3": "B" }, ["q-3", "q-4"]);

    expect(progress).toEqual({ total: 4, answered: 2, unanswered: 2, flagged: 2, percent: 50 });
  });

  it("returns zero percent for an exam with no questions", () => {
    expect(getProgress([], {}, []).percent).toBe(0);
  });

  it("ignores answers and flags for unknown questions", () => {
    const progress = getProgress(IDS, { "q-9": "A" }, ["q-9"]);

    expect(progress.answered).toBe(0);
    expect(progress.flagged).toBe(0);
  });
});

describe("getQuestionStatus", () => {
  it("prioritises flagged over answered over unanswered", () => {
    expect(getQuestionStatus("q-1", { "q-1": "A" }, ["q-1"])).toBe("flagged");
    expect(getQuestionStatus("q-1", { "q-1": "A" }, [])).toBe("answered");
    expect(getQuestionStatus("q-1", {}, [])).toBe("unanswered");
  });
});
