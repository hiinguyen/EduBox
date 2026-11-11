import "server-only";
import { logServerError } from "@/lib/server/log";
import { toActivityEntry } from "./activity";
import { listChildren, selectChild, type ChildRecord } from "./children";
import { buildEffortHighlight, computeStreakDays } from "./effort";
import { buildProgressReport } from "./progress-report";
import { buildLinkedDevices, buildSettings } from "./settings-view";
import { buildWeeklyStats } from "./stats";
import * as queries from "./student-queries";
import type { ActivityEntry, ChildDashboardData, ParentDashboard, UpcomingTask } from "./types";
import { toUpcomingTask } from "./upcoming";
import { currentAcademicYear, toTeacherNote } from "./view-model";

export interface DashboardViewer {
  /** ParentProfile id from the session. */
  readonly profileId: string;
  readonly name: string;
}

async function loadActivityEntries(
  parentId: string,
  studentId: string,
  now: Date,
): Promise<ActivityEntry[]> {
  const rows = await queries.loadActivity(parentId, studentId);
  const entries: ActivityEntry[] = [];
  for (const row of rows) {
    const entry = toActivityEntry(row, now);
    if (entry) entries.push(entry);
    else
      logServerError("phu-huynh.activity", new TypeError("malformed activity JSON"), {
        id: row.id,
      });
  }
  return entries;
}

async function loadUpcomingTasks(
  parentId: string,
  studentId: string,
  now: Date,
): Promise<UpcomingTask[]> {
  const rows = await queries.loadUpcoming(parentId, studentId, now);
  return rows.flatMap((row) =>
    row.dueAt
      ? [
          toUpcomingTask(
            {
              id: row.id,
              kind: row.kind,
              title: row.title,
              subtitle: row.subtitle,
              className: row.class.name,
              dueAt: row.dueAt,
            },
            now,
          ),
        ]
      : [],
  );
}

async function loadStats(parentId: string, child: ChildRecord, now: Date) {
  const studentId = child.profile.id;
  const [studiedSeconds, lessons, grades, aiQuestions] = await Promise.all([
    queries.loadStudiedSeconds(parentId, studentId, now),
    queries.loadLessonCounts(parentId, studentId, now),
    queries.loadGradeSamples(parentId, studentId, now),
    queries.countAiQuestions(parentId, studentId, now),
  ]);
  return buildWeeklyStats({
    studiedSeconds,
    goalMinutes: child.weeklyGoalMinutes,
    watchedLessons: lessons.watched,
    completedLessons: lessons.completed,
    grades,
    aiQuestions,
  });
}

async function loadEffort(parentId: string, child: ChildRecord, now: Date) {
  const [days, badgeTitle] = await Promise.all([
    queries.loadStudyDays(parentId, child.profile.id, now),
    queries.loadRecentBadgeTitle(parentId, child.profile.id, now),
  ]);
  return buildEffortHighlight({
    givenName: child.profile.givenName,
    streakDays: computeStreakDays(days, now),
    recentBadgeTitle: badgeTitle,
  });
}

async function loadChildDashboard(
  parentId: string,
  child: ChildRecord,
  now: Date,
): Promise<ChildDashboardData> {
  const studentId = child.profile.id;
  const [stats, scores, activity, note, upcoming, settings, deviceNames, effort] =
    await Promise.all([
      loadStats(parentId, child, now),
      queries.loadWeekScores(parentId, studentId),
      loadActivityEntries(parentId, studentId, now),
      queries.loadLatestNote(parentId, studentId),
      loadUpcomingTasks(parentId, studentId, now),
      queries.loadSettings(parentId, studentId),
      queries.loadDeviceNames(parentId, studentId),
      loadEffort(parentId, child, now),
    ]);

  return {
    stats,
    progress: buildProgressReport(scores, child.profile.givenName),
    activity,
    teacherNote: note
      ? toTeacherNote(
          { ...note, teacherName: note.teacher.user.name },
          child.profile.className,
          now,
        )
      : null,
    upcoming,
    settings: buildSettings(settings),
    linkedDevices: buildLinkedDevices(deviceNames),
    effort,
  };
}

export type DashboardResult =
  | { readonly status: "ready"; readonly dashboard: ParentDashboard }
  /** The parent has no linked child yet, so there is nothing to select. */
  | { readonly status: "no-children" }
  /** The requested child is not the parent's (indistinguishable from one that does not exist). */
  | { readonly status: "not-found" };

export async function getParentDashboard(
  viewer: DashboardViewer,
  requestedChildId?: string,
  now: Date = new Date(),
): Promise<DashboardResult> {
  const children = await listChildren(viewer.profileId);
  const selected = selectChild(children, requestedChildId);
  if (selected) {
    const data = await loadChildDashboard(viewer.profileId, selected, now);
    const dashboard: ParentDashboard = {
      ...data,
      parent: { displayName: viewer.name },
      academicYear: selected.academicYear ?? currentAcademicYear(now),
      children: children.map((child) => child.profile),
      selectedChild: selected.profile,
    };
    return { status: "ready", dashboard };
  }
  return { status: requestedChildId === undefined ? "no-children" : "not-found" };
}
