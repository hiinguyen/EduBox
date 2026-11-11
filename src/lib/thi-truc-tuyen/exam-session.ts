import "server-only";
import type { SessionUser } from "@/lib/auth/session";
import { assessmentsOfStudent, canStudentAccessAssessment } from "@/lib/auth/access";
import { db } from "@/lib/db";
import { formatRelativeDayLabel } from "@/lib/format/date";
import { DEFAULT_KIND_LABEL, DEFAULT_PROCTOR_STATUS, MAX_QUESTIONS_PER_EXAM } from "./constants";
import { OWNED_ATTEMPT_SELECT } from "./attempt-guard";
import { EXAM_TOOLS } from "./exam-tools";
import { finalizeIfExpired } from "./expire-attempts";
import { readReceipt } from "./receipt";
import { figureSchema, promptSchema } from "./schemas";
import { TAKEABLE } from "./start-attempt";
import type { ExamInfo, ExamIntro, ExamPage, ExamSession, Question, ServerAnswer } from "./types";

const EXAM_SELECT = {
  id: true,
  title: true,
  kindLabel: true,
  proctorStatus: true,
  durationMinutes: true,
  maxScore: true,
  creator: { select: { user: { select: { name: true } } } },
  // No AnswerKey here, ever: correctness never leaves the server.
  questions: {
    where: { type: "MULTIPLE_CHOICE" },
    orderBy: { number: "asc" },
    take: MAX_QUESTIONS_PER_EXAM,
    select: {
      id: true,
      number: true,
      prompt: true,
      figure: true,
      levelLabel: true,
      points: true,
      options: {
        orderBy: { label: "asc" },
        select: { id: true, label: true, text: true },
      },
    },
  },
} as const;

const INTRO_SELECT = {
  id: true,
  title: true,
  kindLabel: true,
  proctorStatus: true,
  durationMinutes: true,
  maxScore: true,
  dueAt: true,
  creator: { select: { user: { select: { name: true } } } },
  _count: { select: { questions: { where: { type: "MULTIPLE_CHOICE" } } } },
} as const;

/**
 * Display only: prefers the exam the student already started, otherwise the oldest one.
 * Looking at an exam never creates an attempt.
 */
async function findDefaultAssessmentId(studentId: string): Promise<string | null> {
  const base = { AND: [assessmentsOfStudent(studentId), TAKEABLE] };
  const started = await db.assessment.findFirst({
    where: { AND: [base, { attempts: { some: { studentId, status: "IN_PROGRESS" } } }] },
    orderBy: [{ createdAt: "asc" }, { id: "asc" }],
    select: { id: true },
  });
  if (started) return started.id;
  const found = await db.assessment.findFirst({
    where: base,
    orderBy: [{ createdAt: "asc" }, { id: "asc" }],
    select: { id: true },
  });
  return found?.id ?? null;
}

async function resolveAssessmentId(studentId: string, requestedId?: string) {
  if (requestedId === undefined) return findDefaultAssessmentId(studentId);
  return (await canStudentAccessAssessment(studentId, requestedId)) ? requestedId : null;
}

type ExamRow = NonNullable<Awaited<ReturnType<typeof loadExam>>>;

function loadExam(assessmentId: string) {
  return db.assessment.findFirst({
    where: { AND: [{ id: assessmentId }, TAKEABLE] },
    select: EXAM_SELECT,
  });
}

function toQuestions(exam: ExamRow): readonly Question[] {
  return exam.questions.map((question) => ({
    id: question.id,
    number: question.number,
    prompt: promptSchema.parse(question.prompt),
    levelLabel: question.levelLabel,
    points: question.points,
    options: question.options,
    ...optionalFigure(question.figure),
  }));
}

function optionalFigure(raw: unknown): { figure?: NonNullable<Question["figure"]> } {
  const figure = figureSchema.parse(raw ?? null);
  return figure ? { figure } : {};
}

async function loadAnswers(attemptId: string): Promise<Readonly<Record<string, ServerAnswer>>> {
  const rows = await db.attemptAnswer.findMany({
    where: { attemptId },
    select: { questionId: true, optionId: true, isFlagged: true, answeredAt: true },
    take: MAX_QUESTIONS_PER_EXAM,
  });
  return Object.fromEntries(
    rows.map((row) => [
      row.questionId,
      { optionId: row.optionId, isFlagged: row.isFlagged, answeredAt: row.answeredAt.getTime() },
    ]),
  );
}

function toExamInfo(
  exam: {
    id: string;
    title: string;
    kindLabel: string | null;
    proctorStatus: string | null;
    maxScore: number;
    creator: { user: { name: string } };
  },
  durationMinutes: number,
): ExamInfo {
  return {
    id: exam.id,
    kindLabel: exam.kindLabel ?? DEFAULT_KIND_LABEL,
    proctorStatus: exam.proctorStatus ?? DEFAULT_PROCTOR_STATUS,
    title: exam.title,
    durationMinutes,
    maxScore: exam.maxScore,
    teacherName: exam.creator.user.name,
  };
}

async function loadIntro(assessmentId: string, now: Date): Promise<ExamIntro | null> {
  const exam = await db.assessment.findFirst({
    where: { AND: [{ id: assessmentId }, TAKEABLE] },
    select: INTRO_SELECT,
  });
  if (!exam || exam.durationMinutes === null) return null;
  return {
    exam: toExamInfo(exam, exam.durationMinutes),
    questionCount: exam._count.questions,
    dueLabel: exam.dueAt ? formatRelativeDayLabel(exam.dueAt, now) : null,
    isOverdue: exam.dueAt !== null && exam.dueAt.getTime() <= now.getTime(),
  };
}

function findAttempt(assessmentId: string, studentId: string) {
  return db.examAttempt.findUnique({
    where: { assessmentId_studentId: { assessmentId, studentId } },
    select: { ...OWNED_ATTEMPT_SELECT, currentIndex: true, updatedAt: true },
  });
}

/** Overdue open attempts are finalised here, so a student never sees one stuck in progress. */
async function findCurrentAttempt(assessmentId: string, studentId: string, now: Date) {
  const attempt = await findAttempt(assessmentId, studentId);
  if (!attempt || !(await finalizeIfExpired(attempt, now))) return attempt;
  return findAttempt(assessmentId, studentId);
}

async function loadSession(
  exam: ExamRow,
  attempt: NonNullable<Awaited<ReturnType<typeof findAttempt>>>,
  durationMinutes: number,
  now: Date,
): Promise<ExamSession> {
  return {
    exam: toExamInfo(exam, durationMinutes),
    attemptId: attempt.id,
    phase: attempt.status,
    endsAt: attempt.endsAt.getTime(),
    serverNow: now.getTime(),
    currentIndex: attempt.currentIndex,
    updatedAt: attempt.updatedAt.getTime(),
    questions: toQuestions(exam),
    tools: EXAM_TOOLS,
    answers: await loadAnswers(attempt.id),
    submission: await readReceipt(attempt.id, attempt.status),
  };
}

/**
 * Read-only: resolves what the exam page shows and never creates an attempt (that is the
 * `startAttempt` action). Deadlines come from the server only.
 */
export async function getExamPage(
  user: SessionUser,
  requestedId?: string,
  now: Date = new Date(),
): Promise<ExamPage> {
  const assessmentId = await resolveAssessmentId(user.profileId, requestedId);
  if (!assessmentId) return { kind: "none" };
  const attempt = await findCurrentAttempt(assessmentId, user.profileId, now);
  if (!attempt) {
    const intro = await loadIntro(assessmentId, now);
    return intro ? { kind: "intro", intro } : { kind: "none" };
  }
  const exam = await loadExam(assessmentId);
  if (!exam || exam.durationMinutes === null) return { kind: "none" };
  return { kind: "session", session: await loadSession(exam, attempt, exam.durationMinutes, now) };
}
