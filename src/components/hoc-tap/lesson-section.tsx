"use client";

import { useState, useTransition } from "react";
import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import { formatSecondsClock } from "@/lib/format/time";
import { updateLessonProgressAction } from "@/lib/hoc-tap/actions";
import { NETWORK_ERROR_MESSAGE } from "@/lib/hoc-tap/chat-client";
import type { FeaturedLesson, LessonChapter, LessonNote } from "@/lib/hoc-tap/types";
import { ComingSoonButton } from "./coming-soon-button";
import { LessonChapters } from "./lesson-chapters";
import { LessonNotes } from "./lesson-notes";
import { VideoPlayer } from "./video-player";

interface LessonSectionProps {
  readonly lesson: FeaturedLesson | null;
}

function byTimestamp(a: LessonNote, b: LessonNote): number {
  return a.atSeconds - b.atSeconds;
}

function EmptyLesson() {
  return (
    <Card as="section" aria-label="Bài giảng đang học">
      <p className="text-center font-body-md text-body-md text-on-surface-variant">
        Chưa có bài giảng nào dành cho lớp của bạn.
      </p>
    </Card>
  );
}

function LessonContent({ lesson }: { readonly lesson: FeaturedLesson }) {
  const [positionSeconds, setPositionSeconds] = useState(lesson.positionSeconds);
  const [notes, setNotes] = useState(lesson.notes);
  const [isNotesOpen, setIsNotesOpen] = useState(false);
  const [progressError, setProgressError] = useState<string | null>(null);
  const [, startTransition] = useTransition();

  function handleChapterSelect(chapter: LessonChapter) {
    setPositionSeconds(chapter.startSeconds);
    startTransition(async () => {
      try {
        const result = await updateLessonProgressAction({
          lessonId: lesson.id,
          positionSeconds: chapter.startSeconds,
        });
        setProgressError(result.ok ? null : result.error.message);
      } catch {
        setProgressError(NETWORK_ERROR_MESSAGE);
      }
    });
  }

  return (
    <Card
      as="section"
      aria-label="Bài giảng đang học"
      className="flex flex-col overflow-hidden p-0!"
    >
      <VideoPlayer lesson={lesson} positionSeconds={positionSeconds} />
      <div className="flex flex-col gap-space-md p-space-lg">
        <div className="flex flex-col justify-between gap-space-md pb-space-md sm:flex-row sm:items-center">
          <div className="min-w-0">
            <span className="font-label-sm text-label-sm font-semibold uppercase tracking-wider text-primary">
              {lesson.topic}
            </span>
            <h2 className="font-headline-md text-headline-md text-on-surface">{lesson.heading}</h2>
            <p className="mt-0.5 flex items-center gap-1.5 font-body-sm text-body-sm text-on-surface-variant">
              <Icon name="account_circle" className="text-[16px] text-outline" />
              <span>{lesson.teacher}</span>
            </p>
          </div>
          <div className="flex flex-wrap items-center gap-space-sm">
            {lesson.handoutName ? (
              <ComingSoonButton className="flex items-center gap-2 rounded-lg bg-surface-container px-space-md py-2 font-label-md text-label-md text-on-surface shadow-sm">
                <Icon name="picture_as_pdf" className="text-[20px] text-primary" />
                <span className="break-all text-left">{lesson.handoutName}</span>
                <Icon name="download" className="text-[18px] text-outline" />
                <span className="sr-only">Tải xuống</span>
              </ComingSoonButton>
            ) : null}
            <button
              type="button"
              aria-expanded={isNotesOpen}
              aria-controls="lesson-notes-panel"
              onClick={() => setIsNotesOpen((previous) => !previous)}
              className="flex items-center gap-2 rounded-lg bg-secondary px-space-md py-2 font-label-md text-label-md text-on-secondary shadow-sm transition-colors hover:bg-secondary/90"
            >
              <Icon name="edit_note" className="text-[20px]" />
              <span>Ghi chú {formatSecondsClock(positionSeconds)}</span>
            </button>
          </div>
        </div>
        {isNotesOpen ? (
          <div id="lesson-notes-panel">
            <LessonNotes
              lessonId={lesson.id}
              positionSeconds={positionSeconds}
              notes={notes}
              onSaved={(note) => setNotes((previous) => [...previous, note].sort(byTimestamp))}
            />
          </div>
        ) : null}
        <LessonChapters
          chapters={lesson.chapters}
          positionSeconds={positionSeconds}
          onSelect={handleChapterSelect}
        />
        {progressError ? (
          <p role="alert" className="font-label-sm text-label-sm text-error">
            {progressError}
          </p>
        ) : null}
      </div>
    </Card>
  );
}

export function LessonSection({ lesson }: LessonSectionProps) {
  return lesson ? <LessonContent lesson={lesson} /> : <EmptyLesson />;
}
