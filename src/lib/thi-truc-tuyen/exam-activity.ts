import type { ActivityDescriptionSegment, ActivityTag } from "@/lib/student/progress-records";
import { roundTo } from "@/lib/format/number";
import type { SubmissionReceipt } from "./types";

const SCORE_DECIMALS = 1;

type FinalStatus = SubmissionReceipt["status"];

interface ExamActivityInput {
  readonly title: string;
  readonly status: FinalStatus;
  readonly score: number;
  readonly correctCount: number;
  readonly totalCount: number;
  readonly isComplete: boolean;
}

interface ExamActivity {
  readonly kind: "EXAM_COMPLETED";
  readonly title: string;
  readonly description: ActivityDescriptionSegment[];
  readonly tags: ActivityTag[];
}

/** Vietnamese parent-portal entry for a finished exam. Never carries answers, only the outcome. */
export function buildExamActivity(input: ExamActivityInput): ExamActivity {
  const { title, status, score, correctCount, totalCount, isComplete } = input;
  const isExpired = status === "EXPIRED";
  const heading = `${isExpired ? "Hết giờ làm bài" : "Hoàn thành bài thi"} ${title}`;
  const description: ActivityDescriptionSegment[] = isComplete
    ? [
        { text: "Đạt kết quả " },
        { text: `${roundTo(score, SCORE_DECIMALS)} điểm`, isEmphasis: true },
        { text: ` (${correctCount}/${totalCount} câu đúng).` },
      ]
    : [{ text: "Bài làm đã được nộp và đang chờ giáo viên chấm phần tự luận." }];
  const tags: ActivityTag[] = [
    isComplete
      ? { label: "Đã chấm tự động", tone: "neutral" }
      : { label: "Chờ giáo viên chấm", tone: "muted" },
  ];
  if (isExpired) tags.push({ label: "Nộp tự động khi hết giờ", tone: "muted" });
  return { kind: "EXAM_COMPLETED", title: heading, description, tags };
}
