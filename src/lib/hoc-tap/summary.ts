import "server-only";
import type { SessionUser } from "@/lib/auth/session";
import { classesOfStudent, upcomingAssessmentsOfStudent } from "@/lib/auth/access";
import { db } from "@/lib/db";
import { getVnCalendarDay } from "@/lib/format/date";
import { getGivenName } from "@/lib/format/name";
import { computeStreak } from "@/lib/student/streak";
import { STUDY_DAY_LOOKBACK } from "./constants";
import type { WeeklySummary } from "./types";
import { computeWeeklyStats, isoWeekNumber, toCalendarDayKey } from "./weekly";

const DEFAULT_TRACK_LABEL = "Học tập cá nhân";

export interface SummaryResult {
  readonly summary: WeeklySummary;
  readonly weekSeconds: number;
}

export async function loadSummary(user: SessionUser, now: Date): Promise<SummaryResult> {
  const today = getVnCalendarDay(now);
  const [profile, studyRows, schoolClass, dueCount] = await Promise.all([
    db.studentProfile.findUnique({
      where: { id: user.profileId },
      select: { weeklyGoalMinutes: true },
    }),
    db.studyDay.findMany({
      where: { studentId: user.profileId },
      orderBy: { day: "desc" },
      take: STUDY_DAY_LOOKBACK,
      select: { day: true, studiedSeconds: true },
    }),
    db.schoolClass.findFirst({
      where: classesOfStudent(user.profileId),
      orderBy: { academicYear: "desc" },
      select: { trackLabel: true },
    }),
    db.assessment.count({ where: upcomingAssessmentsOfStudent(user.profileId, now) }),
  ]);
  const studyDays = studyRows.map((row) => ({
    day: toCalendarDayKey(row.day),
    studiedSeconds: row.studiedSeconds,
  }));
  const stats = computeWeeklyStats(studyDays, now, profile?.weeklyGoalMinutes ?? 0);

  return {
    weekSeconds: stats.weekSeconds,
    summary: {
      studentFirstName: getGivenName(user.name),
      weekLabel: `Tuần ${isoWeekNumber(today)} · ${schoolClass?.trackLabel ?? DEFAULT_TRACK_LABEL}`,
      streakDays: computeStreak(studyDays, today),
      progressPercent: stats.progressPercent,
      goalDeltaPercent: stats.goalDeltaPercent,
      hoursLogged: stats.hoursLogged,
      hoursTarget: stats.hoursTarget,
      dueCount,
    },
  };
}
