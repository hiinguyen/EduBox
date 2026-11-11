import { describe, expect, it } from "vitest";
import { collectPendingItems, markSynced, toSyncedMap } from "./sync";

const IDS = ["q1", "q2", "q3"];

describe("collectPendingItems", () => {
  it("returns nothing when the server already has the same state", () => {
    const synced = toSyncedMap({ q1: { optionId: "a", isFlagged: false, answeredAt: 1 } });

    expect(collectPendingItems(IDS, { q1: "a" }, [], synced)).toEqual([]);
  });

  it("returns new and changed questions only", () => {
    const synced = toSyncedMap({ q1: { optionId: "a", isFlagged: false, answeredAt: 1 } });

    const items = collectPendingItems(IDS, { q1: "b", q2: "c" }, ["q3"], synced);

    expect(items).toEqual([
      { questionId: "q1", optionId: "b", isFlagged: false },
      { questionId: "q2", optionId: "c", isFlagged: false },
      { questionId: "q3", optionId: null, isFlagged: true },
    ]);
  });

  it("sends a cleared flag", () => {
    const synced = toSyncedMap({ q1: { optionId: "a", isFlagged: true, answeredAt: 1 } });

    expect(collectPendingItems(IDS, { q1: "a" }, [], synced)).toEqual([
      { questionId: "q1", optionId: "a", isFlagged: false },
    ]);
  });
});

describe("markSynced", () => {
  it("records acknowledged items without touching others", () => {
    const synced = toSyncedMap({ q1: { optionId: "a", isFlagged: false, answeredAt: 1 } });

    const next = markSynced(synced, [{ questionId: "q2", optionId: "b", isFlagged: false }]);

    expect(next).toEqual({
      q1: { optionId: "a", isFlagged: false },
      q2: { optionId: "b", isFlagged: false },
    });
    expect(synced).not.toHaveProperty("q2");
  });

  it("leaves unacknowledged changes pending", () => {
    const synced = markSynced({}, [{ questionId: "q1", optionId: "a", isFlagged: false }]);

    expect(collectPendingItems(IDS, { q1: "b" }, [], synced)).toHaveLength(1);
  });
});
