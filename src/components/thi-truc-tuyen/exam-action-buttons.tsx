"use client";

import { useExam } from "./exam-provider";
import { SaveDraftButton } from "./save-draft-button";
import { SubmitExamButton } from "./submit-exam-button";

/** Both buttons disappear once the server accepted the submission. */
export function ExamActionButtons() {
  const { submission } = useExam();
  if (submission.receipt) return null;

  return (
    <div className="flex items-center gap-space-sm">
      <SaveDraftButton />
      <SubmitExamButton />
    </div>
  );
}
