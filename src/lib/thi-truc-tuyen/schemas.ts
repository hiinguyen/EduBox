import { z } from "zod";
import { MAX_QUESTIONS_PER_EXAM, MAX_ASSESSMENT_ID_LENGTH } from "./constants";

const idSchema = z.string().min(1).max(MAX_ASSESSMENT_ID_LENGTH);

const saveItemSchema = z.strictObject({
  questionId: idSchema,
  optionId: idSchema.nullable(),
  isFlagged: z.boolean(),
});

const answersSchema = z
  .array(saveItemSchema)
  .max(MAX_QUESTIONS_PER_EXAM)
  .refine((items) => new Set(items.map((item) => item.questionId)).size === items.length, {
    message: "Duplicate question id",
  });

/** Strict on purpose: a client that sends `endsAt` or any other extra field is refused. */
export const saveAnswersInputSchema = z.strictObject({
  attemptId: idSchema,
  currentIndex: z.number().int().nonnegative().optional(),
  answers: answersSchema,
});

export const submitAttemptInputSchema = z.strictObject({
  attemptId: idSchema,
  answers: answersSchema.default([]),
});

export const assessmentQuerySchema = idSchema;

export const startAttemptInputSchema = z.strictObject({ assessmentId: idSchema });

const segmentSchema = z.object({
  kind: z.enum(["text", "math", "code"]),
  text: z.string(),
});

export const promptSchema = z.array(segmentSchema);

export const figureSchema = z
  .object({
    kind: z.literal("derivative-graph"),
    title: z.string(),
    notesTitle: z.string(),
    notes: z.array(promptSchema),
  })
  .nullable();

export type SaveAnswersInput = z.infer<typeof saveAnswersInputSchema>;
export type SubmitAttemptInput = z.infer<typeof submitAttemptInputSchema>;
