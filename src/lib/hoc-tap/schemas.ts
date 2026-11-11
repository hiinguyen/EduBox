import { z } from "zod";
import { MAX_CHAT_LENGTH, MAX_LESSON_SECONDS, MAX_NOTE_LENGTH } from "./constants";

const ID_MAX_LENGTH = 64;

const idSchema = z.string().trim().min(1).max(ID_MAX_LENGTH);

const secondsSchema = z.number().int().min(0).max(MAX_LESSON_SECONDS);

export const chatInputSchema = z
  .string()
  .trim()
  .min(1, "Vui lòng nhập câu hỏi hoặc câu trả lời.")
  .max(MAX_CHAT_LENGTH, `Tin nhắn tối đa ${MAX_CHAT_LENGTH} ký tự.`);

export const chatRequestSchema = z.object({
  message: chatInputSchema,
  threadId: idSchema.optional(),
});

export const saveNoteInputSchema = z.object({
  lessonId: idSchema,
  atSeconds: secondsSchema,
  body: z
    .string()
    .trim()
    .min(1, "Vui lòng nhập nội dung ghi chú.")
    .max(MAX_NOTE_LENGTH, `Ghi chú tối đa ${MAX_NOTE_LENGTH} ký tự.`),
});

export const updateProgressInputSchema = z.object({
  lessonId: idSchema,
  positionSeconds: secondsSchema,
  isCompleted: z.boolean().optional(),
});

export type ChatRequest = z.infer<typeof chatRequestSchema>;
export type SaveNoteInput = z.infer<typeof saveNoteInputSchema>;
export type UpdateProgressInput = z.infer<typeof updateProgressInputSchema>;
