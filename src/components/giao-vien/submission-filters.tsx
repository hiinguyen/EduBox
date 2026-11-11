"use client";

import { useRouter } from "next/navigation";
import { useTransition } from "react";
import { buildWorkspaceHref } from "@/lib/giao-vien/query";
import type { Assessment, ClassOption, GradingSelection } from "@/lib/giao-vien/types";
import { SELECT_CLASS } from "./styles";

interface SubmissionFiltersProps {
  readonly classes: readonly ClassOption[];
  readonly assessments: readonly Assessment[];
  readonly selection: GradingSelection;
  readonly subjectLabel: string;
  readonly lecturePage: number;
}

const LABEL_CLASS = "font-label-sm text-label-sm text-outline";

export function SubmissionFilters({
  classes,
  assessments,
  selection,
  subjectLabel,
  lecturePage,
}: SubmissionFiltersProps) {
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  function navigate(next: { classId: string; assessmentId?: string }) {
    startTransition(() => {
      router.push(buildWorkspaceHref({ ...next, lecturePage }), { scroll: false });
    });
  }

  return (
    <div
      aria-busy={isPending}
      className={`grid grid-cols-1 gap-space-sm sm:grid-cols-3 ${isPending ? "opacity-70" : ""}`}
    >
      <div className="flex min-w-0 flex-col gap-1">
        <label htmlFor="filter-class" className={LABEL_CLASS}>
          Lớp học
        </label>
        <select
          id="filter-class"
          className={SELECT_CLASS}
          value={selection.classId}
          onChange={(event) => navigate({ classId: event.target.value })}
        >
          {classes.map((item) => (
            <option key={item.id} value={item.id}>
              Lớp {item.name} ({item.trackLabel})
            </option>
          ))}
        </select>
      </div>
      <div className="flex min-w-0 flex-col gap-1">
        <span className={LABEL_CLASS}>Môn học</span>
        <p className={`${SELECT_CLASS} flex items-center truncate`}>{subjectLabel}</p>
      </div>
      <div className="flex min-w-0 flex-col gap-1">
        <label htmlFor="filter-assessment" className={LABEL_CLASS}>
          Bài kiểm tra
        </label>
        <select
          id="filter-assessment"
          className={SELECT_CLASS}
          value={selection.assessmentId ?? ""}
          disabled={assessments.length === 0}
          onChange={(event) =>
            navigate({ classId: selection.classId, assessmentId: event.target.value })
          }
        >
          {assessments.length === 0 ? <option value="">Chưa có bài kiểm tra</option> : null}
          {assessments.map((item) => (
            <option key={item.id} value={item.id}>
              {item.title}
            </option>
          ))}
        </select>
      </div>
    </div>
  );
}
