import "server-only";
import { attemptsOfStudent, upcomingAssessmentsOfStudent } from "@/lib/auth/access";
import { db } from "@/lib/db";
import { formatRelativeDayLabel, formatVnClock, getVnCalendarDay } from "@/lib/format/date";
import type { BadgeProgress, Homework } from "./types";
import { badgeHint } from "./weekly";

const DEADLINE_PREFIX = "Hạn";

function formatDeadline(dueAt: Date, now: Date): string {
  const isToday = getVnCalendarDay(dueAt) === getVnCalendarDay(now);
  return `${DEADLINE_PREFIX} ${isToday ? formatVnClock(dueAt) : formatRelativeDayLabel(dueAt, now)}`;
}

export async function loadHomework(studentId: string, now: Date): Promise<Homework | null> {
  const assessment = await db.assessment.findFirst({
    where: upcomingAssessmentsOfStudent(studentId, now),
    orderBy: { dueAt: "asc" },
    select: {
      title: true,
      subtitle: true,
      kindLabel: true,
      dueAt: true,
      _count: { select: { questions: true } },
      attempts: {
        where: attemptsOfStudent(studentId),
        take: 1,
        select: { _count: { select: { answers: true } } },
      },
    },
  });
  if (!assessment?.dueAt) return null;

  return {
    title: assessment.title,
    details: assessment.subtitle ?? assessment.kindLabel ?? "",
    deadlineLabel: formatDeadline(assessment.dueAt, now),
    answered: assessment.attempts[0]?._count.answers ?? 0,
    total: assessment._count.questions,
  };
}

export async function loadBadge(
  studentId: string,
  weekSeconds: number,
): Promise<BadgeProgress | null> {
  const badge = await db.badge.findFirst({
    where: { students: { none: { studentId } } },
    orderBy: { weeklyMinutesToEarn: "asc" },
    select: { title: true, weeklyMinutesToEarn: true },
  });
  if (!badge) return null;

  return {
    title: badge.title,
    description: badgeHint(badge.weeklyMinutesToEarn, weekSeconds),
  };
}
