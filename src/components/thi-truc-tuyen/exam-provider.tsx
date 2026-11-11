"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useReducer,
  useRef,
  useState,
  type ReactNode,
  type RefObject,
} from "react";
import { SAVE_RETRY_DELAY_MS } from "@/lib/thi-truc-tuyen/constants";
import { getClockOffsetMs, toServerTime } from "@/lib/thi-truc-tuyen/clock";
import { isTimeUp } from "@/lib/thi-truc-tuyen/countdown";
import { isDraftChangedElsewhere } from "@/lib/thi-truc-tuyen/draft";
import { INITIAL_DRAFT_STATUS, draftStatusReducer } from "@/lib/thi-truc-tuyen/draft-status";
import type { DraftStatus } from "@/lib/thi-truc-tuyen/draft-status";
import {
  clearDraft,
  getBrowserStorage,
  readDraft,
  writeDraft,
} from "@/lib/thi-truc-tuyen/draft-storage";
import { examReducer, resolveInitialState } from "@/lib/thi-truc-tuyen/exam-state";
import type { ExamAction, ExamState } from "@/lib/thi-truc-tuyen/exam-state";
import { toSyncedMap } from "@/lib/thi-truc-tuyen/sync";
import type { ExamSession, Question } from "@/lib/thi-truc-tuyen/types";
import { ExamSkeleton } from "./exam-skeleton";
import { useIsClient } from "./use-is-client";
import { useNow } from "./use-now";
import { useServerSync } from "./use-server-sync";
import type { ServerSync } from "./use-server-sync";
import { useSubmission } from "./use-submission";
import type { SubmissionControl } from "./use-submission";

interface ExamActions {
  readonly select: (questionId: string, optionId: string) => void;
  readonly setNote: (questionId: string, note: string) => void;
  readonly toggleFlag: (questionId: string) => void;
  readonly goTo: (index: number) => void;
  readonly next: () => void;
  readonly previous: () => void;
  readonly save: () => void;
}

interface ExamContextValue {
  readonly attemptId: string;
  readonly questions: readonly Question[];
  readonly state: ExamState;
  readonly draftStatus: DraftStatus;
  readonly sync: ServerSync;
  readonly submission: SubmissionControl;
  /** Offset to add to the browser clock to get server time. */
  readonly clockOffsetMs: number;
  readonly isTimeUp: boolean;
  /** Time is up or the exam was submitted: nothing is editable any more. */
  readonly isLocked: boolean;
  readonly questionHeadingRef: RefObject<HTMLHeadingElement | null>;
  readonly actions: ExamActions;
}

const ExamContext = createContext<ExamContextValue | null>(null);

export function useExam(): ExamContextValue {
  const value = useContext(ExamContext);
  if (value === null) throw new Error("useExam must be used inside ExamProvider");
  return value;
}

interface ExamProviderProps {
  readonly session: ExamSession;
  readonly children: ReactNode;
}

/**
 * The draft lives in browser storage, so nothing is rendered until the client has
 * taken over. That way server answers are never shown before a newer local draft is merged.
 */
export function ExamProvider(props: ExamProviderProps) {
  const isClient = useIsClient();
  if (!isClient) return <ExamSkeleton />;
  return <ClientExamProvider key={props.session.attemptId} {...props} />;
}

function ClientExamProvider({ session, children }: ExamProviderProps) {
  const { attemptId, questions } = session;
  const [clockOffsetMs] = useState(() => getClockOffsetMs(session.serverNow, Date.now()));
  // The lazy initialiser runs once, so later changes to `session` never replace in-memory answers.
  const [state, dispatch] = useReducer(examReducer, undefined, () =>
    resolveInitialState({
      server: session,
      stored: readDraft(getBrowserStorage(), attemptId, questions),
      questionIds: questions.map((question) => question.id),
      endsAt: session.endsAt,
      now: toServerTime(Date.now(), clockOffsetMs),
    }),
  );
  const questionHeadingRef = useRef<HTMLHeadingElement>(null);
  const isTimeUpNow = isTimeUp(state.endsAt, toServerTime(useNow(), clockOffsetMs));
  const [isFinished, setIsFinished] = useState(
    session.submission !== null || session.phase !== "IN_PROGRESS",
  );
  const isLocked = isTimeUpNow || isFinished;
  const sync = useServerSync({
    attemptId,
    questionIds: useMemo(() => questions.map((question) => question.id), [questions]),
    state,
    initialSynced: useMemo(() => toSyncedMap(session.answers), [session.answers]),
    initialIndex: session.currentIndex,
    isLocked,
  });
  const onSubmitted = useCallback(() => {
    clearDraft(getBrowserStorage(), attemptId);
    setIsFinished(true);
  }, [attemptId]);
  const submission = useSubmission({
    attemptId,
    initialReceipt: session.submission,
    getPendingItems: sync.getPendingItems,
    onSubmitted,
  });
  const draftStatus = useDraftPersistence(attemptId, state, submission.receipt !== null);
  useAutoSubmit(isTimeUpNow, submission);
  const actions = useActions(dispatch, questionHeadingRef, sync.flush, clockOffsetMs);

  const value = useMemo(
    () => ({
      attemptId,
      questions,
      state,
      draftStatus,
      sync,
      submission,
      clockOffsetMs,
      isTimeUp: isTimeUpNow,
      isLocked,
      questionHeadingRef,
      actions,
    }),
    [
      attemptId,
      questions,
      state,
      draftStatus,
      sync,
      submission,
      clockOffsetMs,
      isTimeUpNow,
      isLocked,
      actions,
    ],
  );

  return <ExamContext.Provider value={value}>{children}</ExamContext.Provider>;
}

/** Submits once when the deadline passes, then keeps retrying quietly until the server accepts. */
function useAutoSubmit(isTimeUpNow: boolean, submission: SubmissionControl): void {
  const { receipt, phase, submit } = submission;
  const isPending = phase === "pending";
  const shouldSubmit = isTimeUpNow && receipt === null && !isPending;
  const delay = phase === "error" ? SAVE_RETRY_DELAY_MS : 0;

  useEffect(() => {
    if (!shouldSubmit) return;
    const id = window.setTimeout(() => void submit(), delay);
    return () => window.clearTimeout(id);
  }, [shouldSubmit, delay, submit]);
}

function useDraftPersistence(
  attemptId: string,
  state: ExamState,
  isSubmitted: boolean,
): DraftStatus {
  const [status, report] = useReducer(draftStatusReducer, INITIAL_DRAFT_STATUS);

  useEffect(() => {
    if (isSubmitted) return;
    const didWrite = writeDraft(getBrowserStorage(), attemptId, state);
    report(didWrite ? { type: "written", at: Date.now() } : { type: "writeFailed" });
  }, [attemptId, state, isSubmitted]);

  useEffect(() => {
    const onStorage = (event: StorageEvent) => {
      if (isDraftChangedElsewhere(event, attemptId)) report({ type: "changedElsewhere" });
    };
    window.addEventListener("storage", onStorage);
    return () => window.removeEventListener("storage", onStorage);
  }, [attemptId]);

  return status;
}

function useActions(
  dispatch: (action: ExamAction) => void,
  headingRef: RefObject<HTMLHeadingElement | null>,
  flush: () => Promise<boolean>,
  clockOffsetMs: number,
): ExamActions {
  return useMemo(() => {
    const at = () => toServerTime(Date.now(), clockOffsetMs);
    const navigate = (action: ExamAction) => {
      dispatch(action);
      headingRef.current?.focus();
    };
    return {
      select: (questionId, optionId) =>
        dispatch({ type: "select", questionId, optionId, at: at() }),
      setNote: (questionId, note) => dispatch({ type: "setNote", questionId, note, at: at() }),
      toggleFlag: (questionId) => dispatch({ type: "toggleFlag", questionId, at: at() }),
      goTo: (index) => navigate({ type: "goTo", index, at: at() }),
      next: () => navigate({ type: "next", at: at() }),
      previous: () => navigate({ type: "previous", at: at() }),
      save: () => {
        dispatch({ type: "save", at: at() });
        void flush();
      },
    };
  }, [dispatch, headingRef, flush, clockOffsetMs]);
}
