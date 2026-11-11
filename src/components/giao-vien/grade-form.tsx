"use client";

import { useState } from "react";
import Link from "next/link";
import { Icon } from "@/components/ui/icon";
import { MAX_FEEDBACK_LENGTH, SCORE_STEP } from "@/lib/giao-vien/constants";
import { formatScore, getInitialEssayScore } from "@/lib/giao-vien/grading";
import type { RecordedGrade } from "@/lib/giao-vien/optimistic";
import type { Assessment, SubmissionDetail } from "@/lib/giao-vien/types";
import { AiSuggestionCard } from "./ai-suggestion-card";
import { useGradeSave } from "./use-grade-save";

interface GradeFormProps {
  readonly submission: SubmissionDetail;
  readonly assessment: Assessment;
  readonly teacherName: string;
  readonly nextHref: string | null;
  readonly onRecord: (grade: RecordedGrade) => void;
}

const FIELD_FOCUS = "focus-visible:outline-2 focus-visible:outline-primary";

interface ScoreFieldProps {
  readonly maxScore: number;
  readonly value: string;
  readonly onChange: (value: string) => void;
}

function ScoreField({ maxScore, value, onChange }: ScoreFieldProps) {
  return (
    <div className="flex items-center justify-between gap-space-sm">
      <label
        htmlFor="score-essay"
        className="font-label-sm text-label-sm font-semibold text-on-surface"
      >
        Chấm điểm phần Tự luận (Thang {formatScore(maxScore)}):
      </label>
      <div className="flex shrink-0 items-center gap-1">
        <input
          id="score-essay"
          type="number"
          inputMode="decimal"
          min={0}
          max={maxScore}
          step={SCORE_STEP}
          value={value}
          onChange={(event) => onChange(event.target.value)}
          className={`h-8 w-16 rounded-lg bg-surface-container text-center font-body-sm font-bold text-primary ${FIELD_FOCUS}`}
        />
        <span className="font-label-sm text-label-sm text-outline">/ {formatScore(maxScore)}</span>
      </div>
    </div>
  );
}

interface NotifyParentOptionProps {
  readonly isChecked: boolean;
  readonly onChange: (isChecked: boolean) => void;
}

function NotifyParentOption({ isChecked, onChange }: NotifyParentOptionProps) {
  return (
    <div className="flex items-center gap-space-xs">
      <input
        id="notify-parent"
        type="checkbox"
        checked={isChecked}
        onChange={(event) => onChange(event.target.checked)}
        className={`h-4 w-4 shrink-0 cursor-pointer rounded accent-primary ${FIELD_FOCUS}`}
      />
      <label
        htmlFor="notify-parent"
        className="cursor-pointer select-none font-body-sm text-body-sm text-on-surface-variant"
      >
        Gửi thông báo trong ứng dụng cho phụ huynh
      </label>
    </div>
  );
}

function NextButton({ href }: { readonly href: string | null }) {
  const className = "rounded-lg bg-surface-container-high p-3 text-on-surface transition-colors";
  const label = "Chuyển sang bài tiếp theo";
  if (href === null) {
    return (
      <button
        type="button"
        disabled
        aria-label={label}
        title={label}
        className={`${className} opacity-40`}
      >
        <Icon name="skip_next" className="text-[20px]" />
      </button>
    );
  }
  return (
    <Link
      href={href}
      aria-label={label}
      title={label}
      className={`${className} hover:bg-surface-container ${FIELD_FOCUS}`}
    >
      <Icon name="skip_next" className="text-[20px]" />
    </Link>
  );
}

export function GradeForm(props: GradeFormProps) {
  const { submission, assessment, teacherName, nextHref, onRecord } = props;
  const [scoreText, setScoreText] = useState(() =>
    getInitialEssayScore(submission.essayScore, submission.aiSuggestion?.suggestedScore),
  );
  const [feedback, setFeedback] = useState(submission.feedback);
  const [shouldNotifyParent, setShouldNotifyParent] = useState(!submission.isParentNotified);
  const { save, isSaving, saveFeedback } = useGradeSave(submission.id, onRecord);

  return (
    <>
      {submission.aiSuggestion ? (
        <AiSuggestionCard suggestion={submission.aiSuggestion} onApply={setFeedback} />
      ) : null}
      <div className="flex flex-col gap-space-xs">
        <ScoreField maxScore={assessment.essayMaxScore} value={scoreText} onChange={setScoreText} />
        <label htmlFor="teacher-feedback" className="mt-1 font-label-sm text-label-sm text-outline">
          Lời phê &amp; Nhận xét của {teacherName}:
        </label>
        <textarea
          id="teacher-feedback"
          rows={3}
          maxLength={MAX_FEEDBACK_LENGTH}
          value={feedback}
          onChange={(event) => setFeedback(event.target.value)}
          className={`w-full resize-none rounded-lg bg-surface-container-low p-3 font-body-sm text-body-sm text-on-surface placeholder:text-outline ${FIELD_FOCUS}`}
        />
      </div>
      <NotifyParentOption isChecked={shouldNotifyParent} onChange={setShouldNotifyParent} />
      <p
        role="status"
        className={`min-h-5 font-body-sm text-body-sm ${
          saveFeedback?.tone === "error" ? "text-error" : "text-tertiary"
        }`}
      >
        {saveFeedback?.text}
      </p>
      <div className="flex gap-space-sm">
        <button
          type="button"
          onClick={() => save({ scoreText, feedback, shouldNotifyParent })}
          disabled={isSaving}
          className="flex flex-1 items-center justify-center gap-space-xs rounded-lg bg-primary px-space-md py-3 font-label-md text-label-md text-on-primary shadow-md transition-all hover:bg-primary-container disabled:opacity-60"
        >
          <Icon name="task_alt" className="text-[18px]" />
          <span>{isSaving ? "Đang lưu..." : "Ghi nhận điểm"}</span>
        </button>
        <NextButton href={nextHref} />
      </div>
    </>
  );
}
