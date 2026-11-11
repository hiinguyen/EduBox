import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import type { ExamIntro as ExamIntroData } from "@/lib/thi-truc-tuyen/types";
import { StartExamButton } from "./start-exam-button";

interface ExamIntroProps {
  readonly intro: ExamIntroData;
}

const RULES: readonly string[] = [
  "Đồng hồ bắt đầu chạy ngay khi bạn bấm Bắt đầu làm bài và không thể tạm dừng.",
  "Đáp án được lưu tự động lên máy chủ; nếu mất mạng, bài vẫn được giữ trên thiết bị này.",
  "Hết giờ, bài làm sẽ được nộp tự động và không thể chỉnh sửa.",
  "Mỗi bài thi chỉ được làm một lần. Hãy làm bài ở một tab duy nhất.",
];

export function ExamIntro({ intro }: ExamIntroProps) {
  const { exam, questionCount, dueLabel, isOverdue } = intro;
  const meta: readonly { icon: string; label: string }[] = [
    { icon: "timelapse", label: `${exam.durationMinutes} phút` },
    { icon: "quiz", label: `${questionCount} câu hỏi` },
    { icon: "grade", label: `Điểm tối đa: ${exam.maxScore.toFixed(1)}` },
    { icon: "person", label: exam.teacherName },
  ];

  return (
    <Card
      as="section"
      aria-labelledby="exam-intro-title"
      className="flex w-full flex-col gap-space-lg shadow-md"
    >
      <div className="flex flex-col gap-space-xs">
        <span className="w-fit rounded-full bg-primary-fixed px-2.5 py-1 font-label-sm text-label-sm text-on-primary-fixed">
          {exam.kindLabel}
        </span>
        <h1
          id="exam-intro-title"
          className="font-headline-md text-headline-md tracking-tight text-on-surface"
        >
          {exam.title}
        </h1>
        <ul className="flex flex-wrap items-center gap-x-space-md gap-y-1 font-label-md text-label-md text-on-surface-variant">
          {meta.map((item) => (
            <li key={item.icon} className="flex items-center gap-1">
              <Icon name={item.icon} className="text-[18px]" />
              {item.label}
            </li>
          ))}
        </ul>
      </div>
      <div className="flex flex-col gap-space-sm">
        <h2 className="font-label-md text-label-md font-bold text-on-surface">Quy định làm bài</h2>
        <ul className="flex list-disc flex-col gap-1 pl-5 font-body-md text-body-md text-on-surface-variant">
          {RULES.map((rule) => (
            <li key={rule}>{rule}</li>
          ))}
        </ul>
      </div>
      {dueLabel !== null && (
        <p
          role={isOverdue ? "alert" : undefined}
          className={`flex items-center gap-2 font-label-md text-label-md ${isOverdue ? "text-error" : "text-on-surface-variant"}`}
        >
          <Icon name={isOverdue ? "event_busy" : "event"} className="text-[18px]" />
          {isOverdue ? "Bài thi đã quá hạn nộp" : `Hạn nộp: ${dueLabel}`}
        </p>
      )}
      <StartExamButton assessmentId={exam.id} isDisabled={isOverdue} />
    </Card>
  );
}
