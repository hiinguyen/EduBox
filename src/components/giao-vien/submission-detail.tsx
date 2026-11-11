import { Avatar } from "@/components/ui/avatar";
import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import { formatScore } from "@/lib/giao-vien/grading";
import type { RecordedGrade } from "@/lib/giao-vien/optimistic";
import type { Assessment, SubmissionDetail as SubmissionDetailData } from "@/lib/giao-vien/types";
import { GradeForm } from "./grade-form";

interface SubmissionDetailProps {
  readonly submission: SubmissionDetailData;
  readonly assessment: Assessment;
  readonly classRoomName: string;
  readonly teacherName: string;
  readonly nextHref: string | null;
  readonly onRecord: (grade: RecordedGrade) => void;
}

function DetailHeader({ code }: { readonly code: string }) {
  return (
    <div className="flex items-center justify-between gap-space-sm pb-space-sm">
      <div className="flex items-center gap-space-sm">
        <span
          aria-hidden="true"
          className="h-3 w-3 shrink-0 animate-pulse rounded-full bg-primary"
        />
        <h2 id="detail-title" className="font-headline-sm text-headline-sm text-on-surface">
          Xem nhanh bài nộp chi tiết
        </h2>
      </div>
      <span className="shrink-0 font-label-sm text-label-sm font-semibold text-primary">
        Mã bài: {code}
      </span>
    </div>
  );
}

interface StudentSummaryProps {
  readonly submission: SubmissionDetailData;
  readonly assessment: Assessment;
  readonly classRoomName: string;
}

function StudentSummary({ submission, assessment, classRoomName }: StudentSummaryProps) {
  return (
    <div className="flex items-center justify-between gap-space-sm rounded-lg bg-surface-container-low p-space-md">
      <div className="flex items-center gap-space-sm">
        <Avatar name={submission.studentName} size="lg" tone="primary" maxLetters={1} />
        <div>
          <div className="font-label-md text-label-md font-bold text-on-surface">
            {submission.studentName}
          </div>
          <div className="text-xs text-outline">
            Lớp {classRoomName} · Nộp bài: {submission.submittedTimeLabel}
          </div>
        </div>
      </div>
      <div className="text-right">
        <span className="font-label-sm text-label-sm text-outline">Điểm trắc nghiệm</span>
        <div className="font-headline-sm text-headline-sm text-tertiary">
          {formatScore(submission.multipleChoiceScore)}{" "}
          <span className="text-xs text-outline">
            / {formatScore(assessment.multipleChoiceMaxScore)}
          </span>
        </div>
      </div>
    </div>
  );
}

function EssayPreview({ prompt }: { readonly prompt: string }) {
  return (
    <div className="flex flex-col gap-space-sm">
      <span className="font-label-md text-label-md font-semibold text-on-surface">
        Bài làm tự luận ({prompt})
      </span>
      <div
        role="img"
        aria-label="Ảnh chụp bài làm tự luận của học sinh"
        className="flex h-48 flex-col items-center justify-center gap-1 rounded-lg bg-surface-container-high text-on-surface-variant"
      >
        <Icon name="image" className="text-[40px]" />
        <span className="font-label-sm text-label-sm">Ảnh bài làm tự luận</span>
      </div>
    </div>
  );
}

export function SubmissionDetail({
  submission,
  assessment,
  classRoomName,
  teacherName,
  nextHref,
  onRecord,
}: SubmissionDetailProps) {
  return (
    <Card
      as="section"
      aria-labelledby="detail-title"
      className="flex h-full flex-col gap-space-md xl:sticky xl:top-24"
    >
      <DetailHeader code={submission.code} />
      <StudentSummary
        submission={submission}
        assessment={assessment}
        classRoomName={classRoomName}
      />
      <EssayPreview prompt={assessment.essayPrompt} />
      <GradeForm
        submission={submission}
        assessment={assessment}
        teacherName={teacherName}
        nextHref={nextHref}
        onRecord={onRecord}
      />
    </Card>
  );
}
