import { z } from "zod";
import { MAX_FEEDBACK_LENGTH, MAX_ID_LENGTH, SCORE_STEP } from "./constants";

/** Zod 4 numbers already reject NaN and Infinity. The upper bound comes from the assessment. */
export const gradeInputSchema = z.object({
  submissionId: z.string().trim().min(1).max(MAX_ID_LENGTH),
  essayScore: z.number().min(0).multipleOf(SCORE_STEP),
  feedback: z.string().trim().max(MAX_FEEDBACK_LENGTH),
  shouldNotifyParent: z.boolean(),
});

export type GradeInput = z.infer<typeof gradeInputSchema>;

export function isScoreWithinMax(score: number, maxScore: number): boolean {
  return Number.isFinite(score) && score >= 0 && score <= maxScore;
}

/** AI hint cached on a submission; anything that does not match is treated as absent. */
export const aiSuggestionSchema = z.object({
  comment: z.string().min(1),
  suggestedScore: z.number().min(0),
  feedbackDraft: z.string().min(1).max(MAX_FEEDBACK_LENGTH),
});

export type AiGradingSuggestion = z.infer<typeof aiSuggestionSchema>;

export function parseAiSuggestion(value: unknown): AiGradingSuggestion | null {
  const parsed = aiSuggestionSchema.safeParse(value);
  return parsed.success ? parsed.data : null;
}
