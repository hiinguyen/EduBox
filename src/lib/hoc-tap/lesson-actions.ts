import "server-only";
import { canStudentAccessLesson, notesOfStudent } from "@/lib/auth/access";
import type { SessionUser } from "@/lib/auth/session";
import { db } from "@/lib/db";
import { rateLimit } from "@/lib/rate-limit";
import { fail, failFromZod, ok } from "@/lib/server/action-result";
import type { ActionResult } from "@/lib/server/action-result";
import { logServerError } from "@/lib/server/log";
import { MAX_NOTES_PER_LESSON, NOTE_RATE_LIMIT, NOTE_RATE_WINDOW_MS } from "./constants";
import { commitProgress, type LessonProgressView } from "./lesson-progress";
import { saveNoteInputSchema, updateProgressInputSchema } from "./schemas";
import type { LessonNote } from "./types";

export type { LessonProgressView } from "./lesson-progress";

const LESSON_NOT_FOUND_MESSAGE = "Không tìm thấy bài giảng.";
const NOTE_SAVE_FAILED_MESSAGE = "Không thể lưu ghi chú. Vui lòng thử lại.";
const PROGRESS_SAVE_FAILED_MESSAGE = "Không thể lưu tiến độ học. Vui lòng thử lại.";
const NOTE_RATE_LIMITED_MESSAGE = "Bạn lưu ghi chú quá nhanh. Vui lòng thử lại sau ít phút.";
const NOTE_CAP_MESSAGE = `Bài giảng này đã có tối đa ${MAX_NOTES_PER_LESSON} ghi chú.`;

export async function saveLessonNote(
  user: SessionUser,
  input: unknown,
): Promise<ActionResult<LessonNote>> {
  const parsed = saveNoteInputSchema.safeParse(input);
  if (!parsed.success) return failFromZod(parsed.error);

  try {
    const limit = await rateLimit(`note-save:${user.id}`, {
      limit: NOTE_RATE_LIMIT,
      windowMs: NOTE_RATE_WINDOW_MS,
    });
    if (!limit.isAllowed) return fail("RATE_LIMITED", NOTE_RATE_LIMITED_MESSAGE);
    if (!(await canStudentAccessLesson(user.profileId, parsed.data.lessonId))) {
      return fail("NOT_FOUND", LESSON_NOT_FOUND_MESSAGE);
    }
    const noteCount = await db.note.count({
      where: { AND: [notesOfStudent(user.profileId), { lessonId: parsed.data.lessonId }] },
    });
    if (noteCount >= MAX_NOTES_PER_LESSON) return fail("CONFLICT", NOTE_CAP_MESSAGE);

    const note = await db.note.create({
      data: { studentId: user.profileId, ...parsed.data },
      select: { id: true, atSeconds: true, body: true },
    });
    return ok(note);
  } catch (error) {
    logServerError("save-note", error, { userId: user.id });
    return fail("INTERNAL", NOTE_SAVE_FAILED_MESSAGE);
  }
}

export async function updateLessonProgress(
  user: SessionUser,
  input: unknown,
): Promise<ActionResult<LessonProgressView>> {
  const parsed = updateProgressInputSchema.safeParse(input);
  if (!parsed.success) return failFromZod(parsed.error);

  const { lessonId, positionSeconds, isCompleted } = parsed.data;
  const studentId = user.profileId;
  try {
    if (!(await canStudentAccessLesson(studentId, lessonId))) {
      return fail("NOT_FOUND", LESSON_NOT_FOUND_MESSAGE);
    }
    const write = { studentId, lessonId, positionSeconds, isCompleted, now: new Date() };
    const view = await db.$transaction((tx) => commitProgress(tx, write));
    return ok(view);
  } catch (error) {
    logServerError("update-progress", error, { userId: user.id });
    return fail("INTERNAL", PROGRESS_SAVE_FAILED_MESSAGE);
  }
}
