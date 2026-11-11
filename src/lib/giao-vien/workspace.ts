import "server-only";
import type { SessionUser } from "@/lib/auth/session";
import {
  findDefaultFocus,
  findDetailRecord,
  loadGradingBoard,
  type DetailRecord,
  type FocusTarget,
} from "./grading-queries";
import type { WorkspaceQuery } from "./query";
import type { ClassOption, GradingBoardData, TeacherWorkspace } from "./types";
import { toTeacher } from "./view-models";
import {
  loadClasses,
  loadInsights,
  loadLectures,
  loadStats,
  loadTeacherRecord,
} from "./workspace-queries";

/** Null for a submission id the teacher may not see, so the page answers 404 for both cases. */
async function resolveRequestedSubmission(
  teacherId: string,
  submissionId: string | undefined,
): Promise<DetailRecord | null | "denied"> {
  if (submissionId === undefined) return null;
  return (await findDetailRecord(teacherId, { id: submissionId })) ?? "denied";
}

function toClassOption({ id, name, trackLabel, subjectLabel }: ClassOption): ClassOption {
  return { id, name, trackLabel, subjectLabel };
}

function pickClassId(
  classIds: readonly string[],
  requested: DetailRecord | null,
  query: WorkspaceQuery,
): string | undefined {
  const wanted = requested?.assessment.classId ?? query.classId;
  return classIds.find((id) => id === wanted) ?? classIds[0];
}

/**
 * The single reader for the teacher workspace. Every query ANDs in an access.ts fragment, so
 * ids from the URL can only narrow what the teacher already owns. Returns null when the URL
 * names a submission outside the teacher's classes (same answer as a missing one).
 */
export async function getTeacherWorkspace(
  user: SessionUser,
  query: WorkspaceQuery,
  now: Date = new Date(),
): Promise<TeacherWorkspace | null> {
  const teacherId = user.profileId;
  const requested = await resolveRequestedSubmission(teacherId, query.submissionId);
  if (requested === "denied") return null;

  const [record, classRecords] = await Promise.all([
    loadTeacherRecord(teacherId),
    loadClasses(teacherId),
  ]);
  if (!record) return null;
  const classes = classRecords.map(toClassOption);
  // Classes are ordered by name, so the first one names the term shown in the header.
  const termLabel = classRecords[0]?.termLabel ?? "";

  const classId = pickClassId(
    classes.map((item) => item.id),
    requested,
    query,
  );
  const [stats, lectures, insights, grading] = await Promise.all([
    loadStats(
      teacherId,
      classes.map((item) => item.name),
      now,
    ),
    loadLectures(teacherId, query.lecturePage),
    loadInsights(teacherId),
    classId === undefined
      ? Promise.resolve<GradingBoardData | null>(null)
      : loadGradingBoard({
          teacherId,
          classes,
          classId,
          assessmentId: requested?.assessmentId ?? query.assessmentId,
          requestedPage: query.page,
          requested,
          now,
        }),
  ]);

  const teacher = toTeacher({ ...record, name: record.user.name, termLabel });
  return { teacher, stats, lectures, grading, insights };
}

/**
 * The submission the board would open on when the URL names none, or null when the URL
 * already names one or there is nothing to open. Lets the page redirect before the full load.
 */
export async function findDefaultFocusTarget(
  user: SessionUser,
  query: WorkspaceQuery,
): Promise<FocusTarget | null> {
  if (query.submissionId !== undefined) return null;
  const classes = await loadClasses(user.profileId);
  const classId = pickClassId(
    classes.map((item) => item.id),
    null,
    query,
  );
  if (classId === undefined) return null;
  return findDefaultFocus(user.profileId, classId, query.assessmentId);
}
