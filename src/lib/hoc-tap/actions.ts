"use server";

import { requireRoleForAction } from "@/lib/auth/session";
import { failFromAuth, type ActionResult } from "@/lib/server/action-result";
import { saveLessonNote, updateLessonProgress, type LessonProgressView } from "./lesson-actions";
import type { LessonNote } from "./types";

export async function saveLessonNoteAction(input: unknown): Promise<ActionResult<LessonNote>> {
  const auth = await requireRoleForAction("STUDENT");
  if (!auth.ok) return failFromAuth(auth.error);
  return saveLessonNote(auth.user, input);
}

export async function updateLessonProgressAction(
  input: unknown,
): Promise<ActionResult<LessonProgressView>> {
  const auth = await requireRoleForAction("STUDENT");
  if (!auth.ok) return failFromAuth(auth.error);
  return updateLessonProgress(auth.user, input);
}
