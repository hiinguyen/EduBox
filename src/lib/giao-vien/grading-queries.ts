import "server-only";
import type { Prisma } from "@/generated/prisma/client";
import { assessmentsOfTeacher, submissionsOfTeacher } from "@/lib/auth/access";
import { db } from "@/lib/db";
import { MAX_ASSESSMENTS, SUBMISSIONS_PAGE_SIZE } from "./constants";
import { pageOfIndex, paginate } from "./pagination";
import { toSubmissionDetail, toSubmissionRow } from "./view-models";
import type {
  Assessment,
  ClassOption,
  GradingBoardData,
  SubmissionDetail,
  SubmissionRow,
} from "./types";

const ROW_SELECT = {
  id: true,
  code: true,
  multipleChoiceScore: true,
  submittedAt: true,
  student: { select: { studentCode: true, user: { select: { name: true } } } },
  grade: { select: { essayScore: true } },
} satisfies Prisma.SubmissionSelect;

export const DETAIL_SELECT = {
  ...ROW_SELECT,
  assessmentId: true,
  aiSuggestion: true,
  grade: { select: { essayScore: true, feedback: true, notifiedAt: true } },
  assessment: { select: { classId: true } },
} satisfies Prisma.SubmissionSelect;

export type DetailRecord = Prisma.SubmissionGetPayload<{ select: typeof DETAIL_SELECT }>;

const ORDER = [
  { submittedAt: "asc" },
  { id: "asc" },
] satisfies Prisma.SubmissionOrderByWithRelationInput[];

function loadAssessments(teacherId: string, classId: string): Promise<Assessment[]> {
  return db.assessment
    .findMany({
      where: { AND: [assessmentsOfTeacher(teacherId), { classId, status: { not: "DRAFT" } }] },
      orderBy: [{ createdAt: "asc" }, { id: "asc" }],
      take: MAX_ASSESSMENTS,
      select: {
        id: true,
        title: true,
        essayPrompt: true,
        multipleChoiceMaxScore: true,
        essayMaxScore: true,
      },
    })
    .then((rows) => rows.map((row) => ({ ...row, essayPrompt: row.essayPrompt ?? "" })));
}

export function findDetailRecord(
  teacherId: string,
  where: Prisma.SubmissionWhereInput,
): Promise<DetailRecord | null> {
  return db.submission.findFirst({
    where: { AND: [submissionsOfTeacher(teacherId), where] },
    orderBy: ORDER,
    select: DETAIL_SELECT,
  });
}

/** Pending first, so the board opens on the next piece of work; otherwise the first submission. */
async function pickFocus(
  teacherId: string,
  assessmentId: string,
  pendingCount: number,
): Promise<DetailRecord | null> {
  const where: Prisma.SubmissionWhereInput =
    pendingCount > 0 ? { assessmentId, grade: null } : { assessmentId };
  return findDetailRecord(teacherId, where);
}

export interface FocusTarget {
  readonly classId: string;
  readonly assessmentId: string;
  readonly submissionId: string;
}

/**
 * The submission the board opens on when the URL names none, found with a few cheap queries
 * so the page can pin it in the URL before it loads the rest of the workspace.
 */
export async function findDefaultFocus(
  teacherId: string,
  classId: string,
  requestedAssessmentId: string | undefined,
): Promise<FocusTarget | null> {
  const assessments = await loadAssessments(teacherId, classId);
  const assessment =
    assessments.find((item) => item.id === requestedAssessmentId) ?? assessments[0];
  if (!assessment) return null;

  const first = (where: Prisma.SubmissionWhereInput) =>
    db.submission.findFirst({
      where: { AND: [submissionsOfTeacher(teacherId), { assessmentId: assessment.id }, where] },
      orderBy: ORDER,
      select: { id: true },
    });
  const focus = (await first({ grade: null })) ?? (await first({}));
  return focus ? { classId, assessmentId: assessment.id, submissionId: focus.id } : null;
}

function isBefore(focus: DetailRecord): Prisma.SubmissionWhereInput {
  return {
    OR: [
      { submittedAt: { lt: focus.submittedAt } },
      { submittedAt: focus.submittedAt, id: { lt: focus.id } },
    ],
  };
}

async function findNextPendingId(teacherId: string, focus: DetailRecord): Promise<string | null> {
  const pending: Prisma.SubmissionWhereInput = {
    AND: [
      submissionsOfTeacher(teacherId),
      { assessmentId: focus.assessmentId, grade: null, id: { not: focus.id } },
    ],
  };
  const find = (extra: Prisma.SubmissionWhereInput) =>
    db.submission.findFirst({
      where: { AND: [pending, extra] },
      orderBy: ORDER,
      select: { id: true },
    });
  const next = (await find({ NOT: isBefore(focus) })) ?? (await find({}));
  return next?.id ?? null;
}

interface BoardInput {
  readonly teacherId: string;
  readonly assessmentId: string;
  readonly requestedPage: number | undefined;
  readonly requested: DetailRecord | null;
  readonly now: Date;
}

interface RowsResult {
  readonly rows: readonly SubmissionRow[];
  readonly pagination: ReturnType<typeof paginate>;
  readonly selected: SubmissionDetail | null;
  readonly nextPendingId: string | null;
  readonly pendingCount: number;
}

async function loadRows(input: BoardInput): Promise<RowsResult> {
  const { teacherId, assessmentId, requested, requestedPage, now } = input;
  const scope: Prisma.SubmissionWhereInput = {
    AND: [submissionsOfTeacher(teacherId), { assessmentId }],
  };
  const [total, pendingCount] = await Promise.all([
    db.submission.count({ where: scope }),
    db.submission.count({ where: { AND: [scope, { grade: null }] } }),
  ]);
  const focus = requested ?? (await pickFocus(teacherId, assessmentId, pendingCount));
  const itemsBefore = focus
    ? await db.submission.count({ where: { AND: [scope, isBefore(focus)] } })
    : 0;
  const pagination = paginate(
    total,
    requestedPage ?? pageOfIndex(itemsBefore, SUBMISSIONS_PAGE_SIZE),
    SUBMISSIONS_PAGE_SIZE,
  );
  const [records, nextPendingId] = await Promise.all([
    db.submission.findMany({
      where: scope,
      orderBy: ORDER,
      skip: pagination.skip,
      take: SUBMISSIONS_PAGE_SIZE,
      select: ROW_SELECT,
    }),
    focus ? findNextPendingId(teacherId, focus) : Promise.resolve(null),
  ]);
  return {
    rows: records.map((record) => toSubmissionRow(record, now)),
    pagination,
    selected: focus ? toSubmissionDetail(focus, now) : null,
    nextPendingId,
    pendingCount,
  };
}

const EMPTY_PAGINATION = paginate(0, 1, SUBMISSIONS_PAGE_SIZE);

export interface GradingBoardRequest {
  readonly teacherId: string;
  readonly classes: readonly ClassOption[];
  readonly classId: string;
  readonly assessmentId: string | undefined;
  readonly requestedPage: number | undefined;
  readonly requested: DetailRecord | null;
  readonly now: Date;
}

export async function loadGradingBoard(request: GradingBoardRequest): Promise<GradingBoardData> {
  const { teacherId, classes, classId, requested } = request;
  const classRoom = classes.find((item) => item.id === classId);
  if (!classRoom) throw new Error("Selected class is not one of the teacher's classes");

  const assessments = await loadAssessments(teacherId, classId);
  const assessment = assessments.find((item) => item.id === request.assessmentId) ?? assessments[0];
  const base = {
    classes,
    assessments,
    classRoomName: classRoom.name,
    subjectLabel: classRoom.subjectLabel,
  };
  if (!assessment) {
    return {
      ...base,
      selection: { classId, assessmentId: null },
      rows: [],
      pagination: EMPTY_PAGINATION,
      selected: null,
      nextPendingId: null,
      pendingCount: 0,
    };
  }
  const result = await loadRows({
    teacherId,
    assessmentId: assessment.id,
    requestedPage: request.requestedPage,
    requested: requested?.assessmentId === assessment.id ? requested : null,
    now: request.now,
  });
  return { ...base, selection: { classId, assessmentId: assessment.id }, ...result };
}
