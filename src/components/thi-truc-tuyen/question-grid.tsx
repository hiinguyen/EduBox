"use client";

import { Icon } from "@/components/ui/icon";
import { getQuestionStatus } from "@/lib/thi-truc-tuyen/progress";
import type { QuestionStatus } from "@/lib/thi-truc-tuyen/progress";
import { useExam } from "./exam-provider";

const STATUS_CLASS: Readonly<Record<QuestionStatus, string>> = {
  flagged: "bg-secondary-container text-on-secondary-container",
  answered: "bg-primary-container text-on-primary",
  unanswered: "bg-surface-container-low text-on-surface hover:bg-surface-container",
};

const STATUS_LABEL: Readonly<Record<QuestionStatus, string>> = {
  flagged: "đã gắn cờ",
  answered: "đã làm",
  unanswered: "chưa làm",
};

const CURRENT_CLASS =
  "bg-primary text-on-primary ring-2 ring-primary ring-offset-2 ring-offset-surface-container-lowest";

export function QuestionGrid() {
  const { questions, state, actions, isLocked } = useExam();

  return (
    <ul className="grid grid-cols-5 gap-2">
      {questions.map((question, index) => {
        const status = getQuestionStatus(question.id, state.answers, state.flaggedIds);
        const isCurrent = index === state.currentIndex;
        return (
          <li key={question.id}>
            <button
              type="button"
              disabled={isLocked}
              aria-current={isCurrent ? "step" : undefined}
              aria-label={`Câu ${question.number}, ${STATUS_LABEL[status]}`}
              onClick={() => actions.goTo(index)}
              className={`relative flex h-10 w-full items-center justify-center rounded-lg font-label-md text-label-md font-bold shadow-sm transition-opacity hover:opacity-90 disabled:cursor-not-allowed ${isCurrent ? CURRENT_CLASS : STATUS_CLASS[status]}`}
            >
              {question.number}
              {status === "flagged" && (
                <Icon
                  name="flag"
                  filled
                  className="absolute right-0.5 top-0.5 text-[12px] text-on-secondary-container"
                />
              )}
            </button>
          </li>
        );
      })}
    </ul>
  );
}
