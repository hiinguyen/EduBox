import { isTimeUp } from "./countdown";
import { mergeProgress } from "./merge";
import type { ServerProgress } from "./merge";

export interface StoredExamState {
  readonly answers: Readonly<Record<string, string>>;
  readonly notes: Readonly<Record<string, string>>;
  readonly flaggedIds: readonly string[];
  readonly currentIndex: number;
  /** Server-time milliseconds of the last answer or flag change per question. */
  readonly touchedAt: Readonly<Record<string, number>>;
  readonly savedAt: number;
}

export interface ExamState extends StoredExamState {
  readonly questionCount: number;
  /** Deadline from the server. Never stored in the browser. */
  readonly endsAt: number;
}

export type ExamAction =
  | {
      readonly type: "select";
      readonly questionId: string;
      readonly optionId: string;
      readonly at: number;
    }
  | { readonly type: "toggleFlag"; readonly questionId: string; readonly at: number }
  | {
      readonly type: "setNote";
      readonly questionId: string;
      readonly note: string;
      readonly at: number;
    }
  | { readonly type: "goTo"; readonly index: number; readonly at: number }
  | { readonly type: "next"; readonly at: number }
  | { readonly type: "previous"; readonly at: number }
  | { readonly type: "save"; readonly at: number };

interface InitialStateInput {
  readonly questionCount: number;
  readonly endsAt: number;
  readonly now: number;
  readonly answers?: Readonly<Record<string, string>>;
  readonly flaggedIds?: readonly string[];
  readonly touchedAt?: Readonly<Record<string, number>>;
  readonly notes?: Readonly<Record<string, string>>;
  readonly currentIndex?: number;
}

export function createInitialState(input: InitialStateInput): ExamState {
  return {
    questionCount: input.questionCount,
    answers: input.answers ?? {},
    notes: input.notes ?? {},
    flaggedIds: input.flaggedIds ?? [],
    touchedAt: input.touchedAt ?? {},
    currentIndex: input.currentIndex ?? 0,
    endsAt: input.endsAt,
    savedAt: input.now,
  };
}

interface ResolveInitialStateInput {
  readonly server: ServerProgress;
  readonly stored: StoredExamState | null;
  readonly questionIds: readonly string[];
  /** Absolute deadline from the server. */
  readonly endsAt: number;
  readonly now: number;
}

/** Server answers and the browser draft are merged per question, newest change first. */
export function resolveInitialState(input: ResolveInitialStateInput): ExamState {
  const { server, stored, questionIds, endsAt, now } = input;
  const merged = mergeProgress(server, stored, questionIds);
  return createInitialState({
    questionCount: questionIds.length,
    endsAt,
    now,
    notes: stored?.notes,
    ...merged,
    currentIndex: Math.min(merged.currentIndex, Math.max(0, questionIds.length - 1)),
  });
}

function moveTo(state: ExamState, index: number, at: number): ExamState {
  const isInside = Number.isInteger(index) && index >= 0 && index < state.questionCount;
  return isInside ? { ...state, currentIndex: index, savedAt: at } : state;
}

function toggleFlag(state: ExamState, questionId: string, at: number): ExamState {
  const isFlagged = state.flaggedIds.includes(questionId);
  const flaggedIds = isFlagged
    ? state.flaggedIds.filter((id) => id !== questionId)
    : [...state.flaggedIds, questionId];
  return {
    ...state,
    flaggedIds,
    touchedAt: { ...state.touchedAt, [questionId]: at },
    savedAt: at,
  };
}

/** Answers, notes, flags and navigation are frozen once the deadline has passed. */
export function examReducer(state: ExamState, action: ExamAction): ExamState {
  if (action.type !== "save" && isTimeUp(state.endsAt, action.at)) return state;
  return applyAction(state, action);
}

function applyAction(state: ExamState, action: ExamAction): ExamState {
  switch (action.type) {
    case "select":
      return {
        ...state,
        answers: { ...state.answers, [action.questionId]: action.optionId },
        touchedAt: { ...state.touchedAt, [action.questionId]: action.at },
        savedAt: action.at,
      };
    case "setNote":
      return {
        ...state,
        notes: { ...state.notes, [action.questionId]: action.note },
        savedAt: action.at,
      };
    case "toggleFlag":
      return toggleFlag(state, action.questionId, action.at);
    case "goTo":
      return moveTo(state, action.index, action.at);
    case "next":
      return moveTo(state, state.currentIndex + 1, action.at);
    case "previous":
      return moveTo(state, state.currentIndex - 1, action.at);
    case "save":
      return { ...state, savedAt: action.at };
    default: {
      const unreachable: never = action;
      return unreachable;
    }
  }
}
