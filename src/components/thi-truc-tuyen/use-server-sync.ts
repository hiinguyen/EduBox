import { useCallback, useEffect, useRef, useState } from "react";
import type { ActionErrorCode } from "@/lib/server/action-result";
import { saveAnswers } from "@/lib/thi-truc-tuyen/actions";
import { SAVE_DEBOUNCE_MS, SAVE_RETRY_DELAY_MS } from "@/lib/thi-truc-tuyen/constants";
import type { ExamState } from "@/lib/thi-truc-tuyen/exam-state";
import { collectPendingItems, markSynced } from "@/lib/thi-truc-tuyen/sync";
import type { SaveItem, SyncedMap } from "@/lib/thi-truc-tuyen/sync";

export type SyncStatus = "idle" | "pending" | "saving" | "error";

export interface SyncProblem {
  readonly message: string;
  readonly isRetryable: boolean;
}

export interface ServerSync {
  readonly status: SyncStatus;
  /** Server time of the last batch the server confirmed, or null before the first one. */
  readonly savedAt: number | null;
  readonly problem: SyncProblem | null;
  /** Sends pending changes now; resolves to whether the server confirmed everything. */
  readonly flush: () => Promise<boolean>;
  /** Changes the server has not confirmed yet, to send along with the final submit. */
  readonly getPendingItems: () => readonly SaveItem[];
}

interface SyncInput {
  readonly attemptId: string;
  readonly questionIds: readonly string[];
  readonly state: ExamState;
  readonly initialSynced: SyncedMap;
  readonly initialIndex: number;
  /** Autosave stops once the exam is over; the final submit carries the last changes. */
  readonly isLocked: boolean;
}

const RETRYABLE: readonly ActionErrorCode[] = ["INTERNAL", "RATE_LIMITED"];
const NETWORK_MESSAGE =
  "Chưa lưu được bài lên máy chủ. Đáp án vẫn được giữ trên thiết bị này, đang thử lại.";

interface Confirmed {
  readonly synced: SyncedMap;
  readonly index: number;
}

/** Debounced, batched autosave of answers to the server. Local drafts keep working without it. */
export function useServerSync(input: SyncInput): ServerSync {
  const { attemptId, questionIds, state, isLocked } = input;
  const [confirmed, setConfirmed] = useState<Confirmed>({
    synced: input.initialSynced,
    index: input.initialIndex,
  });
  const [savedAt, setSavedAt] = useState<number | null>(null);
  const [problem, setProblem] = useState<SyncProblem | null>(null);
  const [isSaving, setIsSaving] = useState(false);
  const latest = useRef({ state, confirmed });
  const queue = useRef<Promise<boolean>>(Promise.resolve(true));

  useEffect(() => {
    latest.current = { state, confirmed };
  });

  const pendingFor = useCallback(
    (current: ExamState, synced: SyncedMap) =>
      collectPendingItems(questionIds, current.answers, current.flaggedIds, synced),
    [questionIds],
  );

  const run = useCallback(async (): Promise<boolean> => {
    const { state: current, confirmed: known } = latest.current;
    const items = pendingFor(current, known.synced);
    if (items.length === 0 && current.currentIndex === known.index) return true;
    setIsSaving(true);
    const result = await saveAnswers({
      attemptId,
      currentIndex: current.currentIndex,
      answers: items,
    }).catch(() => null);
    setIsSaving(false);
    if (!result?.ok) {
      const isRetryable = !result || RETRYABLE.includes(result.error.code);
      setProblem({ message: result ? result.error.message : NETWORK_MESSAGE, isRetryable });
      return false;
    }
    const next = { synced: markSynced(known.synced, items), index: current.currentIndex };
    latest.current = { state: current, confirmed: next };
    setConfirmed(next);
    setSavedAt(result.data.savedAt);
    setProblem(null);
    return true;
  }, [attemptId, pendingFor]);

  const flush = useCallback(() => {
    queue.current = queue.current.then(run);
    return queue.current;
  }, [run]);

  const isDirty =
    pendingFor(state, confirmed.synced).length > 0 || state.currentIndex !== confirmed.index;
  const shouldRetry = problem === null || problem.isRetryable;

  useEffect(() => {
    if (!isDirty || isLocked || !shouldRetry) return;
    const delay = problem === null ? SAVE_DEBOUNCE_MS : SAVE_RETRY_DELAY_MS;
    const id = window.setTimeout(() => void flush(), delay);
    return () => window.clearTimeout(id);
  }, [
    isDirty,
    isLocked,
    shouldRetry,
    problem,
    state.answers,
    state.flaggedIds,
    state.currentIndex,
    flush,
  ]);

  const getPendingItems = useCallback(() => {
    const { state: current, confirmed: known } = latest.current;
    return pendingFor(current, known.synced);
  }, [pendingFor]);

  return {
    status: resolveStatus(problem, isSaving, isDirty),
    savedAt,
    problem,
    flush,
    getPendingItems,
  };
}

function resolveStatus(
  problem: SyncProblem | null,
  isSaving: boolean,
  isDirty: boolean,
): SyncStatus {
  if (problem) return "error";
  if (isSaving) return "saving";
  return isDirty ? "pending" : "idle";
}
