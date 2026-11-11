"use client";

import { useId, useState, type KeyboardEvent } from "react";
import { getNextTabIndex } from "@/lib/thi-truc-tuyen/tab-navigation";
import type { Question } from "@/lib/thi-truc-tuyen/types";
import { AnswerOptions } from "./answer-options";
import { useExam } from "./exam-provider";
import { NotePanel } from "./note-panel";

type AnswerTab = "choice" | "note";

const TABS: readonly { readonly id: AnswerTab; readonly label: string }[] = [
  { id: "choice", label: "Trắc nghiệm chọn đáp án" },
  { id: "note", label: "Tải ảnh bài làm / Nhập LaTeX" },
];

interface AnswerSectionProps {
  readonly question: Question;
}

export function AnswerSection({ question }: AnswerSectionProps) {
  const { isLocked } = useExam();
  const [activeTab, setActiveTab] = useState<AnswerTab>("choice");
  const baseId = useId();
  const tabId = (tab: AnswerTab) => `${baseId}-tab-${tab}`;
  const panelId = (tab: AnswerTab) => `${baseId}-panel-${tab}`;

  const handleKeyDown = (event: KeyboardEvent<HTMLDivElement>) => {
    const currentIndex = TABS.findIndex((tab) => tab.id === activeTab);
    const nextIndex = getNextTabIndex(event.key, currentIndex, TABS.length);
    const nextTab = nextIndex === null ? undefined : TABS[nextIndex];
    if (!nextTab) return;
    event.preventDefault();
    setActiveTab(nextTab.id);
    document.getElementById(tabId(nextTab.id))?.focus();
  };

  return (
    <div className="flex flex-col gap-space-md">
      <div
        role="tablist"
        aria-label="Hình thức trả lời"
        onKeyDown={handleKeyDown}
        className="flex w-fit max-w-full flex-wrap items-center gap-space-xs rounded-xl bg-surface-container-high p-1"
      >
        {TABS.map((tab) => {
          const isActive = tab.id === activeTab;
          return (
            <button
              key={tab.id}
              id={tabId(tab.id)}
              type="button"
              role="tab"
              aria-selected={isActive}
              aria-controls={panelId(tab.id)}
              tabIndex={isActive ? 0 : -1}
              onClick={() => setActiveTab(tab.id)}
              className={`rounded-lg px-space-md py-1.5 font-label-md text-label-md transition-all ${isActive ? "bg-surface-container-lowest font-semibold text-primary shadow-sm" : "text-on-surface-variant hover:text-on-surface"}`}
            >
              {tab.label}
            </button>
          );
        })}
      </div>
      <fieldset disabled={isLocked} className="min-w-0">
        <legend className="sr-only">Bài làm câu {question.number}</legend>
        <div
          role="tabpanel"
          id={panelId("choice")}
          aria-labelledby={tabId("choice")}
          hidden={activeTab !== "choice"}
        >
          <AnswerOptions question={question} />
        </div>
        <div
          role="tabpanel"
          id={panelId("note")}
          aria-labelledby={tabId("note")}
          hidden={activeTab !== "note"}
        >
          <NotePanel question={question} />
        </div>
      </fieldset>
    </div>
  );
}
