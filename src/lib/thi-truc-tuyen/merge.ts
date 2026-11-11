import type { ServerAnswer } from "./types";

export interface LocalProgress {
  readonly answers: Readonly<Record<string, string>>;
  readonly flaggedIds: readonly string[];
  /** Server-time milliseconds of the last change per question. */
  readonly touchedAt: Readonly<Record<string, number>>;
  readonly currentIndex: number;
  readonly savedAt: number;
}

export interface ServerProgress {
  readonly answers: Readonly<Record<string, ServerAnswer>>;
  readonly currentIndex: number;
  readonly updatedAt: number;
}

export interface MergedProgress {
  readonly answers: Readonly<Record<string, string>>;
  readonly flaggedIds: readonly string[];
  readonly touchedAt: Readonly<Record<string, number>>;
  readonly currentIndex: number;
}

interface Entry {
  readonly optionId: string | null;
  readonly isFlagged: boolean;
  readonly at: number;
}

function localEntry(local: LocalProgress, questionId: string): Entry | undefined {
  const optionId = local.answers[questionId] ?? null;
  const isFlagged = local.flaggedIds.includes(questionId);
  const at = local.touchedAt[questionId];
  const isKnown = optionId !== null || isFlagged || at !== undefined;
  return isKnown ? { optionId, isFlagged, at: at ?? local.savedAt } : undefined;
}

function serverEntry(server: ServerProgress, questionId: string): Entry | undefined {
  const row = server.answers[questionId];
  return row && { optionId: row.optionId, isFlagged: row.isFlagged, at: row.answeredAt };
}

/** The newer side wins per question; a tie goes to the server so both devices converge. */
function pickEntry(local: Entry | undefined, server: Entry | undefined): Entry | undefined {
  if (!local) return server;
  if (!server) return local;
  return local.at > server.at ? local : server;
}

/**
 * Merges the server's saved progress with the browser draft, deterministically.
 * Both inputs must already be restricted to the exam's real question ids.
 */
export function mergeProgress(
  server: ServerProgress,
  local: LocalProgress | null,
  questionIds: readonly string[],
): MergedProgress {
  const answers: Record<string, string> = {};
  const touchedAt: Record<string, number> = {};
  const flaggedIds: string[] = [];

  for (const id of questionIds) {
    const entry = pickEntry(local ? localEntry(local, id) : undefined, serverEntry(server, id));
    if (!entry) continue;
    touchedAt[id] = entry.at;
    if (entry.optionId !== null) answers[id] = entry.optionId;
    if (entry.isFlagged) flaggedIds.push(id);
  }

  const isLocalNewer = local !== null && local.savedAt > server.updatedAt;
  const currentIndex = isLocalNewer ? local.currentIndex : server.currentIndex;
  return { answers, flaggedIds, touchedAt, currentIndex };
}
