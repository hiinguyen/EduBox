import { z } from "zod";
import type { StoredExamState } from "./exam-state";
import type { Question } from "./types";

export const DRAFT_VERSION = 1;
export const MAX_NOTE_LENGTH = 5_000;

const draftSchema = z.object({
  version: z.literal(DRAFT_VERSION),
  attemptId: z.string(),
  answers: z.record(z.string(), z.string()),
  notes: z.record(z.string(), z.string()).default({}),
  flaggedIds: z.array(z.string()),
  currentIndex: z.number().int().nonnegative(),
  touchedAt: z.record(z.string(), z.number().finite()).default({}),
  savedAt: z.number().finite(),
});

/** A storage event only fires in other tabs, so any change to our key came from one. */
export function isDraftChangedElsewhere(
  event: Pick<StorageEvent, "key" | "newValue">,
  attemptId: string,
): boolean {
  return event.key === getDraftStorageKey(attemptId) && event.newValue !== null;
}

/** One key per attempt, so a draft can never leak into another attempt or exam. */
export function getDraftStorageKey(attemptId: string): string {
  return `edubox:exam-draft:v${DRAFT_VERSION}:${attemptId}`;
}

/** The deadline is deliberately absent: only the server decides when the exam ends. */
export function serializeDraft(attemptId: string, draft: StoredExamState): string {
  const { answers, notes, flaggedIds, currentIndex, touchedAt, savedAt } = draft;
  return JSON.stringify({
    version: DRAFT_VERSION,
    attemptId,
    answers,
    notes,
    flaggedIds,
    currentIndex,
    touchedAt,
    savedAt,
  });
}

function parseJson(raw: string): unknown {
  try {
    return JSON.parse(raw);
  } catch {
    return null;
  }
}

function pickKnownAnswers(
  answers: Readonly<Record<string, string>>,
  questions: readonly Question[],
): Record<string, string> {
  const entries = questions.flatMap((question) => {
    const optionId = answers[question.id];
    const isKnownOption = question.options.some((option) => option.id === optionId);
    return optionId !== undefined && isKnownOption ? [[question.id, optionId] as const] : [];
  });
  return Object.fromEntries(entries);
}

function pickKnownNotes(
  notes: Readonly<Record<string, string>>,
  questions: readonly Question[],
): Record<string, string> {
  const entries = questions.flatMap((question) => {
    const note = notes[question.id];
    return note === undefined ? [] : [[question.id, note.slice(0, MAX_NOTE_LENGTH)] as const];
  });
  return Object.fromEntries(entries);
}

function pickKnownTimes(
  touchedAt: Readonly<Record<string, number>>,
  knownIds: ReadonlySet<string>,
): Record<string, number> {
  return Object.fromEntries(Object.entries(touchedAt).filter(([id]) => knownIds.has(id)));
}

/**
 * Parses a stored draft against the real exam. A draft for another attempt is ignored,
 * and entries that do not belong to the exam are dropped one by one so a single bad
 * entry never discards valid work.
 */
export function parseDraft(
  raw: string | null,
  questions: readonly Question[],
  attemptId: string,
): StoredExamState | null {
  if (raw === null || questions.length === 0) return null;
  const result = draftSchema.safeParse(parseJson(raw));
  if (!result.success || result.data.attemptId !== attemptId) return null;
  const { answers, notes, flaggedIds, currentIndex, touchedAt, savedAt } = result.data;
  const knownIds = new Set(questions.map((question) => question.id));
  return {
    answers: pickKnownAnswers(answers, questions),
    notes: pickKnownNotes(notes, questions),
    flaggedIds: [...new Set(flaggedIds.filter((id) => knownIds.has(id)))],
    currentIndex: Math.min(currentIndex, questions.length - 1),
    touchedAt: pickKnownTimes(touchedAt, knownIds),
    savedAt,
  };
}
