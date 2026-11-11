import { useState, useTransition } from "react";
import { saveGradeAction } from "@/lib/giao-vien/actions";
import type { RecordedGrade } from "@/lib/giao-vien/optimistic";
import { DEFAULT_ERROR_MESSAGES } from "@/lib/server/action-result";

const EMPTY_SCORE_MESSAGE = "Vui lòng nhập điểm tự luận.";
const INVALID_SCORE_MESSAGE = "Điểm tự luận phải là một số hợp lệ.";

export type SaveFeedback = { readonly tone: "error" | "success"; readonly text: string } | null;

interface GradeDraft {
  readonly scoreText: string;
  readonly feedback: string;
  readonly shouldNotifyParent: boolean;
}

type ParsedScore = { readonly score: number } | { readonly error: string };

function parseScore(scoreText: string): ParsedScore {
  if (scoreText.trim() === "") return { error: EMPTY_SCORE_MESSAGE };
  const score = Number(scoreText);
  return Number.isFinite(score) ? { score } : { error: INVALID_SCORE_MESSAGE };
}

/**
 * Saves a grade through the Server Action. The optimistic grade lives only for the duration of
 * the transition, so on any failure React restores the server data and the error stays visible.
 */
export function useGradeSave(
  submissionId: string,
  recordOptimistic: (grade: RecordedGrade) => void,
) {
  const [saveFeedback, setSaveFeedback] = useState<SaveFeedback>(null);
  const [isSaving, startSaving] = useTransition();

  function save({ scoreText, feedback, shouldNotifyParent }: GradeDraft) {
    const parsed = parseScore(scoreText);
    if ("error" in parsed) {
      setSaveFeedback({ tone: "error", text: parsed.error });
      return;
    }
    setSaveFeedback(null);
    startSaving(async () => {
      recordOptimistic({ submissionId, essayScore: parsed.score });
      try {
        const result = await saveGradeAction({
          submissionId,
          essayScore: parsed.score,
          feedback,
          shouldNotifyParent,
        });
        setSaveFeedback(
          result.ok
            ? { tone: "success", text: result.data.message }
            : { tone: "error", text: result.error.message },
        );
      } catch {
        setSaveFeedback({ tone: "error", text: DEFAULT_ERROR_MESSAGES.INTERNAL });
      }
    });
  }

  return { save, isSaving, saveFeedback };
}
