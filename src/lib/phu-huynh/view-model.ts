import { formatRelativeAgo, getVnCalendarDay } from "@/lib/format/date";
import type { ChildProfile, TeacherNote } from "./types";

/** The only child fields a client component needs to render the switcher. */
export interface ChildOption {
  readonly id: string;
  readonly name: string;
  readonly className: string;
  readonly studentCode: string;
}

export function toChildOption(child: ChildProfile): ChildOption {
  return {
    id: child.id,
    name: child.fullName,
    className: child.className,
    studentCode: child.studentCode,
  };
}

export interface TeacherNoteRow {
  readonly id: string;
  readonly subject: string;
  readonly weekLabel: string;
  readonly message: string;
  readonly createdAt: Date;
  readonly acknowledgedAt: Date | null;
  readonly teacherName: string;
}

export function toTeacherNote(row: TeacherNoteRow, className: string, now: Date): TeacherNote {
  return {
    id: row.id,
    isAcknowledged: row.acknowledgedAt !== null,
    teacherName: row.teacherName,
    subject: row.subject,
    role: `Giáo viên bộ môn ${row.subject} ${className}`,
    sentAgo: formatRelativeAgo(row.createdAt, now),
    weekLabel: row.weekLabel,
    message: row.message,
  };
}

const ACADEMIC_YEAR_START_MONTH = 9;
const YEAR_MONTH_PATTERN = /^(\d{4})-(\d{2})/;

/** Vietnamese school year containing `now` in Vietnam time, e.g. "2026-2027" from September 2026. */
export function currentAcademicYear(now: Date): string {
  const match = YEAR_MONTH_PATTERN.exec(getVnCalendarDay(now));
  const year = Number(match?.[1]);
  const month = Number(match?.[2]);
  const start = month >= ACADEMIC_YEAR_START_MONTH ? year : year - 1;
  return `${start}-${start + 1}`;
}
