import Link from "next/link";
import { Avatar } from "@/components/ui/avatar";
import { Pill } from "@/components/ui/pill";
import { formatScoreOutOf, needsReview } from "@/lib/giao-vien/grading";
import type { Assessment, SubmissionRow as SubmissionRowData } from "@/lib/giao-vien/types";
import { ERROR_PILL_CLASS } from "./styles";

interface SubmissionsTableProps {
  readonly assessment: Assessment;
  readonly submissions: readonly SubmissionRowData[];
  readonly selectedId: string | null;
  readonly hrefFor: (submissionId: string) => string;
}

const ROW_DEFAULT = "hover:bg-surface-container-low";
const ROW_SELECTED = "bg-primary-fixed/20 hover:bg-primary-fixed/30";
// The sticky action cell is opaque so scrolled cells never show through, so the row tint is layered inside it.
const ROW_DEFAULT_INNER = "group-hover:bg-surface-container-low";
const ROW_SELECTED_INNER = "bg-primary-fixed/20 group-hover:bg-primary-fixed/30";
const STICKY_CELL = "sticky right-0";
const HEAD_CELL = "p-space-sm font-label-sm text-label-sm";

function getActionLabel(isSelected: boolean, isPending: boolean): string {
  if (isSelected) return "Đang mở";
  return isPending ? "Chấm" : "Chi tiết";
}

function SubmissionRow({
  submission,
  assessment,
  isSelected,
  href,
}: {
  readonly submission: SubmissionRowData;
  readonly assessment: Assessment;
  readonly isSelected: boolean;
  readonly href: string;
}) {
  const isPending = needsReview(submission);
  const actionLabel = getActionLabel(isSelected, isPending);
  const actionTone = isSelected
    ? "bg-primary text-on-primary"
    : "bg-surface-container-high text-on-surface-variant hover:text-on-surface";

  return (
    <tr className={`group transition-colors ${isSelected ? ROW_SELECTED : ROW_DEFAULT}`}>
      <th scope="row" className="p-space-sm text-left font-normal">
        <div className="flex items-center gap-space-sm">
          <Avatar name={submission.studentName} size="sm" tone="primary" maxLetters={1} />
          <div>
            <div
              className={`font-label-md text-label-md text-on-surface ${isSelected ? "font-semibold" : ""}`}
            >
              {submission.studentName}
            </div>
            <div className="text-xs text-outline">SBD: {submission.studentNumber}</div>
          </div>
        </div>
      </th>
      <td className="whitespace-nowrap p-space-sm text-on-surface-variant">
        {submission.submittedAtLabel}
      </td>
      <td className="whitespace-nowrap p-space-sm text-center font-semibold text-tertiary">
        {formatScoreOutOf(submission.multipleChoiceScore, assessment.multipleChoiceMaxScore)}
      </td>
      <td className="whitespace-nowrap p-space-sm text-center">
        {submission.essayScore === null ? (
          <span className="font-bold text-error">Chờ chấm</span>
        ) : (
          <span className="font-semibold text-tertiary">
            {formatScoreOutOf(submission.essayScore, assessment.essayMaxScore)}
          </span>
        )}
      </td>
      <td className="p-space-sm">
        <Pill tone="success" className={`whitespace-nowrap ${isPending ? ERROR_PILL_CLASS : ""}`}>
          {isPending ? "Cần duyệt" : "Đã hoàn tất"}
        </Pill>
      </td>
      <td className={`${STICKY_CELL} bg-surface-container-lowest p-0`}>
        <div
          className={`p-space-sm text-right transition-colors ${
            isSelected ? ROW_SELECTED_INNER : ROW_DEFAULT_INNER
          }`}
        >
          <Link
            href={href}
            scroll={false}
            aria-label={`${actionLabel} bài nộp của ${submission.studentName}`}
            aria-current={isSelected ? "true" : undefined}
            className={`inline-block whitespace-nowrap rounded px-space-sm py-1 font-label-sm text-label-sm transition-colors focus-visible:outline-2 focus-visible:outline-primary ${actionTone}`}
          >
            {actionLabel}
          </Link>
        </div>
      </td>
    </tr>
  );
}

export function SubmissionsTable({
  assessment,
  submissions,
  selectedId,
  hrefFor,
}: SubmissionsTableProps) {
  if (submissions.length === 0) {
    return (
      <p className="rounded-lg bg-surface-container-low p-space-lg text-center font-body-sm text-body-sm text-on-surface-variant">
        Chưa có bài nộp nào cho bài kiểm tra này.
      </p>
    );
  }
  return (
    <div className="overflow-x-auto">
      <table className="w-full min-w-[34rem] text-left font-body-sm text-body-sm">
        <caption className="sr-only">Danh sách bài nộp của {assessment.title}</caption>
        <thead>
          <tr className="bg-surface-container-low text-on-surface-variant">
            <th scope="col" className={`${HEAD_CELL} rounded-l-lg`}>
              Học sinh
            </th>
            <th scope="col" className={HEAD_CELL}>
              Nộp lúc
            </th>
            <th scope="col" className={`${HEAD_CELL} text-center`}>
              Trắc nghiệm
            </th>
            <th scope="col" className={`${HEAD_CELL} text-center`}>
              Tự luận
            </th>
            <th scope="col" className={HEAD_CELL}>
              Trạng thái
            </th>
            <th
              scope="col"
              className={`${HEAD_CELL} ${STICKY_CELL} rounded-r-lg bg-surface-container-low text-right`}
            >
              Xem
            </th>
          </tr>
        </thead>
        <tbody>
          {submissions.map((submission) => (
            <SubmissionRow
              key={submission.id}
              submission={submission}
              assessment={assessment}
              isSelected={submission.id === selectedId}
              href={hrefFor(submission.id)}
            />
          ))}
        </tbody>
      </table>
    </div>
  );
}
