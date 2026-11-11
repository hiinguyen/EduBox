"use client";

import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import { AnswerSection } from "./answer-section";
import { DerivativeGraph } from "./derivative-graph";
import { useExam } from "./exam-provider";
import { PromptText } from "./prompt-text";
import { QuestionFooter } from "./question-footer";

export function QuestionCard() {
  const { questions, state, actions, isLocked, questionHeadingRef } = useExam();
  const question = questions[state.currentIndex];
  if (!question) return null;
  const isFlagged = state.flaggedIds.includes(question.id);

  return (
    <Card as="article" className="flex flex-col gap-space-lg shadow-md">
      <div className="flex flex-wrap items-center justify-between gap-2">
        <div className="flex flex-wrap items-center gap-2">
          <h2
            ref={questionHeadingRef}
            tabIndex={-1}
            className="rounded-md bg-primary-container px-3 py-1 font-label-md text-label-md font-bold text-on-primary focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-primary"
          >
            Câu hỏi {question.number}
          </h2>
          <span role="status" className="sr-only">
            Câu {question.number}
          </span>
          <span className="rounded-md bg-surface-container-high px-2.5 py-1 font-label-sm text-label-sm font-semibold text-on-surface-variant">
            {question.levelLabel} · {question.points.toFixed(1)} điểm
          </span>
        </div>
        <button
          type="button"
          aria-pressed={isFlagged}
          disabled={isLocked}
          onClick={() => actions.toggleFlag(question.id)}
          className={`flex items-center gap-1.5 rounded-lg px-3 py-1.5 font-label-sm text-label-sm transition-colors ${isFlagged ? "bg-secondary-fixed text-on-secondary-fixed" : "bg-surface-container text-on-surface-variant hover:bg-secondary-fixed hover:text-on-secondary-fixed"} disabled:cursor-not-allowed disabled:opacity-60`}
        >
          <Icon name="bookmark" filled={isFlagged} className="text-[18px]" />
          {isFlagged ? "Bỏ đánh dấu câu hỏi" : "Đánh dấu câu hỏi này"}
        </button>
      </div>
      <div className="flex flex-col gap-space-md">
        <p className="font-body-lg text-body-lg font-medium leading-relaxed text-on-surface">
          <PromptText segments={question.prompt} />
        </p>
        {question.figure && <DerivativeGraph figure={question.figure} />}
      </div>
      <AnswerSection key={question.id} question={question} />
      <QuestionFooter />
    </Card>
  );
}
