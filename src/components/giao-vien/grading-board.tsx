"use client";

import { useOptimistic, type ReactNode } from "react";
import { Card } from "@/components/ui/card";
import { Pill } from "@/components/ui/pill";
import { applyRecordedGrade, type GradingView } from "@/lib/giao-vien/optimistic";
import { buildWorkspaceHref } from "@/lib/giao-vien/query";
import type { Assessment, GradingBoardData } from "@/lib/giao-vien/types";
import { PaginationNav } from "./pagination-nav";
import { ERROR_PILL_CLASS } from "./styles";
import { SubmissionDetail } from "./submission-detail";
import { SubmissionFilters } from "./submission-filters";
import { SubmissionsTable } from "./submissions-table";

interface GradingBoardProps {
  readonly board: GradingBoardData;
  readonly teacherName: string;
  readonly lecturePage: number;
  readonly children: ReactNode;
}

function PendingPill({ count }: { readonly count: number }) {
  return (
    <Pill
      tone="success"
      className={`self-start whitespace-nowrap sm:self-auto ${count > 0 ? ERROR_PILL_CLASS : ""}`}
    >
      {count > 0 ? `${count} bài chờ chấm` : "Đã chấm xong"}
    </Pill>
  );
}

function EmptyNotice({ text }: { readonly text: string }) {
  return (
    <p className="rounded-lg bg-surface-container-low p-space-lg text-center font-body-sm text-body-sm text-on-surface-variant">
      {text}
    </p>
  );
}

interface GradingPanelProps {
  readonly board: GradingBoardData;
  readonly view: GradingView;
  readonly assessment: Assessment | undefined;
  readonly lecturePage: number;
}

function GradingPanel({ board, view, assessment, lecturePage }: GradingPanelProps) {
  const { selection, pagination } = board;
  const hrefFor = (page: number, submissionId?: string) =>
    buildWorkspaceHref({ ...selection, lecturePage, page, submissionId });

  return (
    <Card as="section" aria-labelledby="grading-title" className="flex flex-col gap-space-md">
      <div className="flex flex-col justify-between gap-space-sm sm:flex-row sm:items-center">
        <div>
          <h2 id="grading-title" className="font-headline-sm text-headline-sm text-on-surface">
            Bảng chấm điểm &amp; Đánh giá bài nộp
          </h2>
          <p className="font-body-sm text-body-sm text-on-surface-variant">
            Lọc theo khối lớp và bài tập cần hoàn thành nhận xét
          </p>
        </div>
        <PendingPill count={view.pendingCount} />
      </div>
      <SubmissionFilters
        classes={board.classes}
        assessments={board.assessments}
        selection={selection}
        subjectLabel={board.subjectLabel}
        lecturePage={lecturePage}
      />
      {assessment ? (
        <SubmissionsTable
          assessment={assessment}
          submissions={view.rows}
          selectedId={view.selected?.id ?? null}
          hrefFor={(submissionId) => hrefFor(pagination.page, submissionId)}
        />
      ) : (
        <EmptyNotice text="Lớp này chưa có bài kiểm tra nào." />
      )}
      <PaginationNav
        label="Phân trang danh sách bài nộp"
        pagination={pagination}
        hrefForPage={(page) => hrefFor(page, view.selected?.id)}
      />
    </Card>
  );
}

function EmptyDetail() {
  return (
    <Card as="section" className="xl:sticky xl:top-24">
      <h2 className="font-headline-sm text-headline-sm text-on-surface">
        Xem nhanh bài nộp chi tiết
      </h2>
      <p className="mt-space-sm font-body-sm text-body-sm text-on-surface-variant">
        Chưa có bài nộp nào để chấm.
      </p>
    </Card>
  );
}

/**
 * Client boundary of the grading board. Everything shown comes from the server render; the only
 * client state is the optimistic grade that bridges the Server Action round trip.
 */
export function GradingBoard({ board, teacherName, lecturePage, children }: GradingBoardProps) {
  const serverView: GradingView = {
    rows: board.rows,
    selected: board.selected,
    pendingCount: board.pendingCount,
  };
  const [view, recordOptimistic] = useOptimistic(serverView, applyRecordedGrade);
  const assessment = board.assessments.find((item) => item.id === board.selection.assessmentId);
  const nextHref = board.nextPendingId
    ? buildWorkspaceHref({
        ...board.selection,
        page: board.pagination.page,
        submissionId: board.nextPendingId,
        lecturePage,
      })
    : null;

  return (
    <div className="grid grid-cols-1 gap-space-lg xl:grid-cols-12">
      <div className="flex min-w-0 flex-col gap-space-md xl:col-span-7">
        <GradingPanel board={board} view={view} assessment={assessment} lecturePage={lecturePage} />
        {children}
      </div>
      <div className="flex min-w-0 flex-col xl:col-span-5">
        {view.selected && assessment ? (
          <SubmissionDetail
            key={view.selected.id}
            submission={view.selected}
            assessment={assessment}
            classRoomName={board.classRoomName}
            teacherName={teacherName}
            nextHref={nextHref}
            onRecord={recordOptimistic}
          />
        ) : (
          <EmptyDetail />
        )}
      </div>
    </div>
  );
}
