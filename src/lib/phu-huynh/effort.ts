import { computeStreak } from "@/lib/student/streak";
import { getVnCalendarDay } from "@/lib/format/date";
import { studyDayKey } from "./study-window";
import type { EffortHighlight } from "./types";

export interface StudyDaySample {
  /** Midnight UTC of the calendar day (a `@db.Date` value). */
  readonly day: Date;
  readonly studiedSeconds: number;
}

/** Streak of the student screen: the shared rule, evaluated on the Vietnam calendar. */
export function computeStreakDays(days: readonly StudyDaySample[], now: Date): number {
  const entries = days.map((sample) => ({
    day: studyDayKey(sample.day),
    studiedSeconds: sample.studiedSeconds,
  }));
  return computeStreak(entries, getVnCalendarDay(now));
}

const EYEBROW = "Ghi nhận nỗ lực tuần";

export function buildEffortHighlight(input: {
  readonly givenName: string;
  readonly streakDays: number;
  readonly recentBadgeTitle: string | null;
}): EffortHighlight {
  const { givenName, streakDays, recentBadgeTitle } = input;
  if (recentBadgeTitle) {
    return {
      eyebrow: EYEBROW,
      title: `${givenName} vừa đạt ${recentBadgeTitle}`,
      body: "Phụ huynh hãy dành một lời khen để ghi nhận thành quả của con nhé!",
    };
  }
  if (streakDays > 0) {
    return {
      eyebrow: EYEBROW,
      title: `${givenName} đã tự giác học ${streakDays} ngày liên tục`,
      body: "Phụ huynh hãy dành một lời khen hoặc phần thưởng nhỏ cuối tuần để khích lệ tinh thần học tập tự chủ của con nhé!",
    };
  }
  return {
    eyebrow: EYEBROW,
    title: `Cùng ${givenName} xây dựng thói quen học đều`,
    body: "Chưa có chuỗi ngày học liên tục. Một buổi học ngắn mỗi ngày sẽ giúp con tiến bộ đều hơn.",
  };
}
