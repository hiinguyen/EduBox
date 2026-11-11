import type { AssessmentKind } from "@/generated/prisma/enums";
import {
  addDaysToVnDay,
  formatRelativeDayLabel,
  formatVnClock,
  getVnCalendarDay,
} from "@/lib/format/date";
import { MS_PER_HOUR } from "@/lib/format/time";
import { URGENT_WINDOW_HOURS } from "./constants";
import type { DeadlineBadge, UpcomingTask } from "./types";

const KIND_BADGE: Readonly<Record<AssessmentKind, { icon: string; caption: string }>> = {
  HOMEWORK: { icon: "assignment", caption: "Bài tập" },
  QUIZ: { icon: "quiz", caption: "Kiểm tra" },
  EXAM: { icon: "event_note", caption: "Kỳ thi" },
};

export interface UpcomingRow {
  readonly id: string;
  readonly kind: AssessmentKind;
  readonly title: string;
  readonly subtitle: string | null;
  readonly className: string;
  readonly dueAt: Date;
}

/** "Hôm nay 21:00", "Ngày mai 21:00", otherwise "dd/MM HH:mm", all in Vietnam time. */
export function formatDueLabel(dueAt: Date, now: Date): string {
  const tomorrow = addDaysToVnDay(getVnCalendarDay(now), 1);
  if (getVnCalendarDay(dueAt) === tomorrow) return `Ngày mai ${formatVnClock(dueAt)}`;
  return formatRelativeDayLabel(dueAt, now);
}

function buildBadge(kind: AssessmentKind, hoursLeft: number, isUrgent: boolean): DeadlineBadge {
  if (isUrgent) {
    return {
      kind: "countdown",
      value: `${Math.max(1, Math.ceil(hoursLeft))}H`,
      caption: "Hạn chót",
    };
  }
  return { kind: "icon", ...KIND_BADGE[kind] };
}

export function toUpcomingTask(row: UpcomingRow, now: Date): UpcomingTask {
  const hoursLeft = (row.dueAt.getTime() - now.getTime()) / MS_PER_HOUR;
  const isUrgent = hoursLeft <= URGENT_WINDOW_HOURS;
  return {
    id: row.id,
    title: row.title,
    subtitle: row.subtitle ?? `Lớp ${row.className}`,
    dueLabel: formatDueLabel(row.dueAt, now),
    isUrgent,
    badge: buildBadge(row.kind, hoursLeft, isUrgent),
  };
}
