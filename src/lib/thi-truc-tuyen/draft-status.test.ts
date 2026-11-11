import { describe, expect, it } from "vitest";
import { INITIAL_DRAFT_STATUS, draftStatusReducer } from "./draft-status";

describe("draftStatusReducer", () => {
  it("records the saved time after a successful write", () => {
    const status = draftStatusReducer(INITIAL_DRAFT_STATUS, { type: "written", at: 5_000 });

    expect(status).toMatchObject({ savedAt: 5_000, hasStorageFailed: false });
  });

  it("keeps the previous saved time when a write fails", () => {
    const saved = draftStatusReducer(INITIAL_DRAFT_STATUS, { type: "written", at: 5_000 });

    const status = draftStatusReducer(saved, { type: "writeFailed" });

    expect(status).toMatchObject({ savedAt: 5_000, hasStorageFailed: true });
  });

  it("never sets a saved time when the very first write fails", () => {
    const status = draftStatusReducer(INITIAL_DRAFT_STATUS, { type: "writeFailed" });

    expect(status.savedAt).toBeNull();
  });

  it("clears the failure once a later write succeeds", () => {
    const failed = draftStatusReducer(INITIAL_DRAFT_STATUS, { type: "writeFailed" });

    const status = draftStatusReducer(failed, { type: "written", at: 9_000 });

    expect(status).toMatchObject({ savedAt: 9_000, hasStorageFailed: false });
  });

  it("flags a change from another tab without touching the save state", () => {
    const status = draftStatusReducer(INITIAL_DRAFT_STATUS, { type: "changedElsewhere" });

    expect(status).toMatchObject({ isOpenInAnotherTab: true, savedAt: null });
  });
});
