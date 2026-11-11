import { getDraftStorageKey, parseDraft, serializeDraft } from "./draft";
import type { StoredExamState } from "./exam-state";
import type { Question } from "./types";

/** Reading `window.localStorage` itself can throw when site data is blocked. */
export function getBrowserStorage(): Storage | null {
  try {
    return window.localStorage;
  } catch {
    return null;
  }
}

export function readDraft(
  storage: Storage | null,
  attemptId: string,
  questions: readonly Question[],
): StoredExamState | null {
  if (storage === null) return null;
  try {
    return parseDraft(storage.getItem(getDraftStorageKey(attemptId)), questions, attemptId);
  } catch {
    return null;
  }
}

export function writeDraft(
  storage: Storage | null,
  attemptId: string,
  draft: StoredExamState,
): boolean {
  if (storage === null) return false;
  try {
    storage.setItem(getDraftStorageKey(attemptId), serializeDraft(attemptId, draft));
    return true;
  } catch {
    return false;
  }
}

/** Removes the draft once the server has the final answers. Failures are harmless. */
export function clearDraft(storage: Storage | null, attemptId: string): void {
  if (storage === null) return;
  try {
    storage.removeItem(getDraftStorageKey(attemptId));
  } catch {
    // Nothing to do: a draft that cannot be removed is ignored on the next load anyway.
  }
}
