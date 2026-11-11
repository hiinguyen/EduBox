"use client";

import { Icon } from "@/components/ui/icon";
import type { Question } from "@/lib/thi-truc-tuyen/types";
import { useExam } from "./exam-provider";

interface AnswerOptionsProps {
  readonly question: Question;
}

export function AnswerOptions({ question }: AnswerOptionsProps) {
  const { state, actions } = useExam();
  const selectedId = state.answers[question.id];
  const groupName = `answer-${question.id}`;

  return (
    <div
      role="radiogroup"
      aria-label={`Đáp án câu hỏi ${question.number}`}
      className="grid grid-cols-1 gap-space-md md:grid-cols-2"
    >
      {question.options.map((option) => {
        const isSelected = option.id === selectedId;
        return (
          <label
            key={option.id}
            className={`group relative flex cursor-pointer items-center rounded-xl p-space-md shadow-sm transition-all has-[:focus-visible]:outline-2 has-[:focus-visible]:outline-offset-2 has-[:focus-visible]:outline-primary has-[:disabled]:cursor-not-allowed has-[:disabled]:opacity-60 active:scale-[0.99] ${isSelected ? "bg-surface-container-high" : "bg-surface-container-low hover:bg-surface-container"}`}
          >
            <input
              type="radio"
              name={groupName}
              value={option.id}
              checked={isSelected}
              onChange={() => actions.select(question.id, option.id)}
              className="sr-only"
            />
            <span
              aria-hidden="true"
              className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-full font-bold transition-colors ${isSelected ? "bg-primary text-on-primary shadow-sm" : "bg-surface-container-highest text-on-surface"}`}
            >
              {option.label}
            </span>
            <span
              className={`ml-space-md font-headline-sm text-headline-sm transition-colors ${isSelected ? "font-bold text-primary" : "text-on-surface group-hover:text-primary"}`}
            >
              {option.text}
            </span>
            {isSelected && <Icon name="check_circle" className="ml-auto text-primary" />}
          </label>
        );
      })}
    </div>
  );
}
