import { roundTo } from "@/lib/format/number";
import { clampPercent, MAX_PERCENT } from "@/lib/format/percent";
import {
  AI_QUESTIONS_WEEKLY_TARGET,
  MINUTES_PER_HOUR,
  SCORE_SCALE,
  SECONDS_PER_HOUR,
} from "./constants";
import type { WeeklyStat } from "./types";

export interface GradeSample {
  /** Multiple-choice plus essay score. */
  readonly earned: number;
  readonly maxScore: number;
}

export interface WeeklyStatInput {
  readonly studiedSeconds: number;
  readonly goalMinutes: number;
  readonly watchedLessons: number;
  readonly completedLessons: number;
  readonly grades: readonly GradeSample[];
  readonly aiQuestions: number;
}

const HOUR_DECIMALS = 1;
const SCORE_DECIMALS = 1;

/** Mean of the grades normalised to a 10-point scale, or null when nothing is graded. */
export function averageScore(grades: readonly GradeSample[]): number | null {
  const usable = grades.filter((grade) => grade.maxScore > 0);
  if (usable.length === 0) return null;
  const total = usable.reduce(
    (sum, grade) => sum + (grade.earned / grade.maxScore) * SCORE_SCALE,
    0,
  );
  return roundTo(total / usable.length, SCORE_DECIMALS);
}

function buildOnlineTime(input: WeeklyStatInput): WeeklyStat {
  const hours = input.studiedSeconds / SECONDS_PER_HOUR;
  const goalHours = input.goalMinutes / MINUTES_PER_HOUR;
  const percent = goalHours > 0 ? Math.round((hours / goalHours) * MAX_PERCENT) : 0;
  const surplus = roundTo(hours - goalHours, HOUR_DECIMALS);
  const suffix = surplus > 0 ? ` (+${surplus}h)` : "";
  return {
    id: "online-time",
    label: "Thời gian học trực tuyến",
    icon: "hourglass_top",
    value: String(roundTo(hours, HOUR_DECIMALS)),
    unit: "giờ / tuần",
    detail: { kind: "trend", text: `Đạt ${percent}% mục tiêu tuần${suffix}` },
    progressPercent: clampPercent(percent),
  };
}

function buildLectures(input: WeeklyStatInput): WeeklyStat {
  const { watchedLessons, completedLessons } = input;
  const percent =
    watchedLessons > 0 ? Math.round((completedLessons / watchedLessons) * MAX_PERCENT) : 0;
  return {
    id: "lectures",
    label: "Số bài giảng đã xem",
    icon: "smart_display",
    value: String(watchedLessons),
    unit: "bài học",
    detail:
      watchedLessons > 0
        ? { kind: "verified", prefix: "Tỷ lệ xem trọn vẹn: ", emphasis: `${percent}%` }
        : { kind: "note", text: "Chưa xem bài giảng nào trong tuần" },
    progressPercent: clampPercent(percent),
  };
}

function buildAverageScore(input: WeeklyStatInput): WeeklyStat {
  const average = averageScore(input.grades);
  return {
    id: "average-score",
    label: "Điểm trung bình bài tập",
    icon: "military_tech",
    value: average === null ? "-" : String(average),
    unit: "/ 10 điểm",
    detail:
      average === null
        ? { kind: "note", text: "Chưa có bài nào được chấm" }
        : { kind: "badge", text: `Tính trên ${input.grades.length} bài đã chấm` },
    progressPercent: clampPercent(((average ?? 0) / SCORE_SCALE) * MAX_PERCENT),
  };
}

function buildAiQuestions(input: WeeklyStatInput): WeeklyStat {
  const percent = Math.round((input.aiQuestions / AI_QUESTIONS_WEEKLY_TARGET) * MAX_PERCENT);
  return {
    id: "ai-questions",
    label: "Hỏi đáp Gia sư AI",
    icon: "psychology",
    value: String(input.aiQuestions),
    unit: "câu tư duy",
    detail: { kind: "note", text: "Số câu hỏi gửi Gia sư AI trong tuần này" },
    progressPercent: clampPercent(percent),
  };
}

export function buildWeeklyStats(input: WeeklyStatInput): readonly WeeklyStat[] {
  return [
    buildOnlineTime(input),
    buildLectures(input),
    buildAverageScore(input),
    buildAiQuestions(input),
  ];
}
