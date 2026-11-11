import type { ServerAnswer } from "./types";

/** What the server holds for one question, as far as this browser knows. */
export interface SyncedEntry {
  readonly optionId: string | null;
  readonly isFlagged: boolean;
}

export interface SaveItem {
  readonly questionId: string;
  readonly optionId: string | null;
  readonly isFlagged: boolean;
}

export type SyncedMap = Readonly<Record<string, SyncedEntry>>;

export function toSyncedMap(answers: Readonly<Record<string, ServerAnswer>>): SyncedMap {
  return Object.fromEntries(
    Object.entries(answers).map(([id, row]) => [
      id,
      { optionId: row.optionId, isFlagged: row.isFlagged },
    ]),
  );
}

/** Only questions that differ from what the server already has are sent. */
export function collectPendingItems(
  questionIds: readonly string[],
  answers: Readonly<Record<string, string>>,
  flaggedIds: readonly string[],
  synced: SyncedMap,
): readonly SaveItem[] {
  return questionIds.flatMap((questionId) => {
    const optionId = answers[questionId] ?? null;
    const isFlagged = flaggedIds.includes(questionId);
    const known = synced[questionId];
    const isUnchanged = known
      ? known.optionId === optionId && known.isFlagged === isFlagged
      : optionId === null && !isFlagged;
    return isUnchanged ? [] : [{ questionId, optionId, isFlagged }];
  });
}

/** Marks exactly the items that were acknowledged by the server as synced. */
export function markSynced(synced: SyncedMap, items: readonly SaveItem[]): SyncedMap {
  const next: Record<string, SyncedEntry> = { ...synced };
  for (const { questionId, optionId, isFlagged } of items)
    next[questionId] = { optionId, isFlagged };
  return next;
}
