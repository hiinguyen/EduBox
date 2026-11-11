export interface DraftStatus {
  /** Time of the last successful local write, or null before the first one. */
  readonly savedAt: number | null;
  readonly hasStorageFailed: boolean;
  readonly isOpenInAnotherTab: boolean;
}

export type DraftStatusEvent =
  | { readonly type: "written"; readonly at: number }
  | { readonly type: "writeFailed" }
  | { readonly type: "changedElsewhere" };

export const INITIAL_DRAFT_STATUS: DraftStatus = {
  savedAt: null,
  hasStorageFailed: false,
  isOpenInAnotherTab: false,
};

/** The saved time only moves on a successful write, so it never claims work that was not stored. */
export function draftStatusReducer(status: DraftStatus, event: DraftStatusEvent): DraftStatus {
  switch (event.type) {
    case "written":
      return { ...status, savedAt: event.at, hasStorageFailed: false };
    case "writeFailed":
      return { ...status, hasStorageFailed: true };
    case "changedElsewhere":
      return { ...status, isOpenInAnotherTab: true };
    default: {
      const unreachable: never = event;
      return unreachable;
    }
  }
}
