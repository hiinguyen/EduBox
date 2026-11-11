import type { AssessmentStatus } from "@/generated/prisma/enums";
import type { SessionUser } from "@/lib/auth/session";
import { db } from "@/lib/db";
import { startAttemptFor } from "@/lib/thi-truc-tuyen/start-attempt";
import { createTaggedWorld } from "./world";
import type { TaggedWorld } from "./world";

export const EXAM_DURATION_MINUTES = 50;
export const QUESTION_POINTS = 2.5;
export const QUESTION_COUNT = 4;
const OPTION_LABELS = ["A", "B", "C", "D"] as const;

export interface ExamFixture {
  readonly id: string;
  readonly questionIds: readonly string[];
  /** optionIds[question index][label index]; label index 0 (A) is the correct answer. */
  readonly optionIds: readonly (readonly string[])[];
}

export interface ExamOptions {
  readonly name: string;
  readonly essayMaxScore?: number;
  readonly withEssayQuestion?: boolean;
  readonly questionCount?: number;
  readonly status?: AssessmentStatus;
  readonly dueAt?: Date | null;
}

export interface ExamWorld {
  readonly tagged: TaggedWorld;
  readonly classId: string;
  readonly otherClassId: string;
  readonly teacherId: string;
  readonly teacherUserId: string;
  readonly parentUserId: string;
  readonly exam: ExamFixture;
  readonly essayExam: ExamFixture;
  readonly createExam: (options: ExamOptions) => Promise<ExamFixture>;
  /** A new student enrolled in `classId` (default: the exam class), with a unique tagged email. */
  readonly createStudent: (classId?: string) => Promise<SessionUser>;
  /** Starts the exam through the real start path. Fails the test when the start is refused. */
  readonly startExam: (student: SessionUser, examId: string, now?: Date) => Promise<string>;
  readonly cleanup: () => Promise<void>;
}

async function createQuestion(assessmentId: string, number: number) {
  const question = await db.question.create({
    data: {
      assessmentId,
      number,
      prompt: [{ kind: "text", text: `Câu ${number}` }],
      levelLabel: "Nhận biết",
      points: QUESTION_POINTS,
    },
  });
  const options = await Promise.all(
    OPTION_LABELS.map((label) =>
      db.option.create({ data: { questionId: question.id, label, text: label } }),
    ),
  );
  await db.answerKey.create({ data: { questionId: question.id, optionId: options[0]?.id ?? "" } });
  return { id: question.id, optionIds: options.map((option) => option.id) };
}

async function insertExam(classId: string, creatorId: string, tag: string, o: ExamOptions) {
  const assessment = await db.assessment.create({
    data: {
      classId,
      creatorId,
      kind: "EXAM",
      subject: "MATH",
      title: `${o.name}-${tag}`,
      status: o.status ?? "PUBLISHED",
      durationMinutes: EXAM_DURATION_MINUTES,
      essayMaxScore: o.essayMaxScore ?? 0,
      dueAt: o.dueAt ?? null,
    },
  });
  const questions = [];
  for (let number = 1; number <= (o.questionCount ?? QUESTION_COUNT); number += 1) {
    questions.push(await createQuestion(assessment.id, number));
  }
  if (o.withEssayQuestion) {
    await db.question.create({
      data: {
        assessmentId: assessment.id,
        number: questions.length + 1,
        type: "ESSAY",
        prompt: [{ kind: "text", text: "Tự luận" }],
        levelLabel: "Vận dụng",
        points: 1,
      },
    });
  }
  return {
    id: assessment.id,
    questionIds: questions.map((q) => q.id),
    optionIds: questions.map((q) => q.optionIds),
  };
}

async function insertStudent(classId: string, tag: string, counter: number): Promise<SessionUser> {
  const email = `exam-student-${counter}.${tag}@test.local`;
  const user = await db.user.create({
    data: { email, name: `student ${counter}`, role: "STUDENT" },
    select: { id: true },
  });
  const profile = await db.studentProfile.create({
    data: { userId: user.id, studentCode: `EX-${counter}-${tag}` },
  });
  await db.enrollment.create({ data: { classId, studentId: profile.id } });
  return { id: user.id, role: "STUDENT", name: `student ${counter}`, email, profileId: profile.id };
}

/** Exam-specific fixtures on top of the shared tagged world; everything is removed by `cleanup`. */
export async function createExamWorld(): Promise<ExamWorld> {
  const tagged = await createTaggedWorld();
  const { world, tag } = tagged;
  const teacher = await db.teacherProfile.findUniqueOrThrow({ where: { id: world.teacherA } });
  const parent = await db.parentProfile.findUniqueOrThrow({ where: { id: world.parentA } });
  const createExam = (options: ExamOptions) =>
    insertExam(world.classA, world.teacherA, tag, options);
  const exam = await createExam({ name: "exam" });
  const essayExam = await createExam({
    name: "essay",
    essayMaxScore: 4,
    withEssayQuestion: true,
  });
  const students: SessionUser[] = [];
  const createStudent = async (classId: string = world.classA) => {
    const student = await insertStudent(classId, tag, students.length + 1);
    students.push(student);
    return student;
  };
  const startExam = async (student: SessionUser, examId: string, now = new Date()) => {
    const result = await startAttemptFor(student, { assessmentId: examId }, now);
    if (!result.ok) throw new Error(`start refused: ${result.error.code}`);
    return result.data.attemptId;
  };
  const cleanup = async () => {
    const keys = students.flatMap((s) =>
      ["exam-save", "exam-submit", "exam-start"].map((prefix) => `${prefix}:${s.id}`),
    );
    await db.rateLimitBucket.deleteMany({ where: { key: { in: keys } } });
    await tagged.cleanup();
  };
  return {
    tagged,
    classId: world.classA,
    otherClassId: world.classB,
    teacherId: world.teacherA,
    teacherUserId: teacher.userId,
    parentUserId: parent.userId,
    exam,
    essayExam,
    createExam,
    createStudent,
    startExam,
    cleanup,
  };
}

/** A save item for question `question` choosing label index `label` (0 is A, the correct one). */
export function answerItem(
  exam: ExamFixture,
  question: number,
  label: number | null,
  isFlagged = false,
) {
  return {
    questionId: exam.questionIds[question] ?? "",
    optionId: label === null ? null : (exam.optionIds[question]?.[label] ?? ""),
    isFlagged,
  };
}
