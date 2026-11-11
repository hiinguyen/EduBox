import { Prisma } from "../../src/generated/prisma/client";
import {
  EXAM,
  FILLER_CODE_START,
  FILLER_PENDING_COUNT,
  GRADING_ASSESSMENTS,
  HOMEWORK_06,
  MAX_SCORE,
  NAMED_SUBMISSIONS,
  TEACHER_INSIGHTS,
  UPCOMING,
  type SeedAssessment,
} from "../seed-data/assessments";
import { SEED_QUESTIONS } from "../seed-data/exam-questions";
import { localTime, lookup, type SeedContext } from "./context";

const GRADING_DEADLINE_HOUR = 18;
const HOMEWORK_DUE_HOUR = 23;
const HOMEWORK_DUE_MINUTE = 59;
const FILLER_CLASS_KEY = "12a1";
const GRADER = "ha";
const QUIZ_ID = "asm-kt45-cuc-tri";

async function seedAssessmentRow(
  { db, classIds, teacherIds }: SeedContext,
  item: SeedAssessment,
): Promise<void> {
  const fields = {
    classId: lookup(classIds, item.classKey),
    creatorId: lookup(teacherIds, item.creator),
    kind: item.kind,
    subject: item.subject,
    title: item.title,
    essayPrompt: item.essayPrompt,
    maxScore: MAX_SCORE,
    multipleChoiceMaxScore: item.multipleChoiceMaxScore,
    essayMaxScore: item.essayMaxScore,
    status: "PUBLISHED" as const,
    gradingDueAt: localTime(0, GRADING_DEADLINE_HOUR),
  };
  await db.assessment.upsert({
    where: { id: item.id },
    update: fields,
    create: { id: item.id, ...fields },
  });
}

async function seedQuestionBank({ db }: SeedContext, assessmentId: string): Promise<void> {
  for (const question of SEED_QUESTIONS) {
    const questionId = `${assessmentId}-q${question.number}`;
    const fields = {
      assessmentId,
      number: question.number,
      prompt: question.prompt as unknown as Prisma.InputJsonValue,
      levelLabel: question.levelLabel,
      points: question.points,
      figure: (question.figure ?? undefined) as Prisma.InputJsonValue | undefined,
    };
    await db.question.upsert({
      where: { id: questionId },
      update: fields,
      create: { id: questionId, ...fields },
    });

    for (const [index, text] of question.options.entries()) {
      const label = String.fromCharCode("A".charCodeAt(0) + index);
      const optionId = `${questionId}-${label}`;
      await db.option.upsert({
        where: { id: optionId },
        update: { label, text },
        create: { id: optionId, questionId, label, text },
      });
    }
    await db.answerKey.upsert({
      where: { questionId },
      update: { optionId: `${questionId}-${question.correctLabel}` },
      create: { questionId, optionId: `${questionId}-${question.correctLabel}` },
    });
  }
}

async function seedExamAndHomework(context: SeedContext): Promise<void> {
  const { db, classIds, teacherIds } = context;
  const classId = lookup(classIds, FILLER_CLASS_KEY);
  const exam = {
    classId,
    creatorId: lookup(teacherIds, "dung"),
    kind: "EXAM" as const,
    subject: "MATH" as const,
    title: EXAM.title,
    kindLabel: EXAM.kindLabel,
    proctorStatus: EXAM.proctorStatus,
    durationMinutes: EXAM.durationMinutes,
    maxScore: MAX_SCORE,
    multipleChoiceMaxScore: MAX_SCORE,
    status: "PUBLISHED" as const,
  };
  const homework = {
    classId,
    creatorId: lookup(teacherIds, GRADER),
    kind: "HOMEWORK" as const,
    subject: "MATH" as const,
    title: HOMEWORK_06.title,
    subtitle: HOMEWORK_06.subtitle,
    durationMinutes: HOMEWORK_06.durationMinutes,
    maxScore: MAX_SCORE,
    multipleChoiceMaxScore: MAX_SCORE,
    status: "PUBLISHED" as const,
    dueAt: localTime(0, HOMEWORK_DUE_HOUR, HOMEWORK_DUE_MINUTE),
  };
  await db.assessment.upsert({
    where: { id: EXAM.id },
    update: exam,
    create: { id: EXAM.id, ...exam },
  });
  await db.assessment.upsert({
    where: { id: HOMEWORK_06.id },
    update: homework,
    create: { id: HOMEWORK_06.id, ...homework },
  });
  await seedQuestionBank(context, EXAM.id);
  await seedQuestionBank(context, HOMEWORK_06.id);
}

async function seedUpcoming({ db, classIds, teacherIds }: SeedContext): Promise<void> {
  for (const item of UPCOMING) {
    const fields = {
      classId: lookup(classIds, FILLER_CLASS_KEY),
      creatorId: lookup(teacherIds, GRADER),
      kind: item.kind,
      subject: item.subject,
      title: item.title,
      subtitle: item.subtitle,
      status: "PUBLISHED" as const,
      isOnline: item.isOnline,
      dueAt: localTime(item.dueInDays, item.dueHour),
    };
    await db.assessment.upsert({
      where: { id: item.id },
      update: fields,
      create: { id: item.id, ...fields },
    });
  }
}

interface SubmissionSeed {
  readonly studentId: string;
  readonly assessmentId: string;
  readonly code: string;
  readonly submittedAt: Date;
  readonly multipleChoiceScore: number;
  readonly aiSuggestion: Prisma.InputJsonValue | null;
  readonly essayScore: number | null;
}

async function upsertSubmission(
  { db, teacherIds }: SeedContext,
  input: SubmissionSeed,
): Promise<void> {
  const { essayScore, aiSuggestion, ...rest } = input;
  const fields = { ...rest, aiSuggestion: aiSuggestion ?? Prisma.JsonNull };
  const submission = await db.submission.upsert({
    where: {
      assessmentId_studentId: { assessmentId: input.assessmentId, studentId: input.studentId },
    },
    update: fields,
    create: fields,
    select: { id: true },
  });

  if (essayScore === null) {
    return;
  }
  const grade = {
    gradedById: lookup(teacherIds, GRADER),
    essayScore,
    feedback: "Bài làm tốt, cần cẩn thận hơn ở phần biến đổi đại số.",
  };
  await db.grade.upsert({
    where: { submissionId: submission.id },
    update: grade,
    create: { submissionId: submission.id, ...grade },
  });
}

async function seedSubmissions(context: SeedContext): Promise<void> {
  for (const item of NAMED_SUBMISSIONS) {
    const [hour, minute, second] = item.time;
    await upsertSubmission(context, {
      studentId: lookup(context.studentIds, item.studentKey),
      assessmentId: item.assessmentId,
      code: item.code,
      submittedAt: localTime(0, hour, minute, second),
      multipleChoiceScore: item.multipleChoiceScore,
      aiSuggestion: item.aiSuggestion,
      essayScore: item.essayScore,
    });
  }

  for (let index = 0; index < FILLER_PENDING_COUNT; index += 1) {
    await upsertSubmission(context, {
      studentId: lookup(context.studentIds, `${FILLER_CLASS_KEY}-${index + 1}`),
      assessmentId: QUIZ_ID,
      code: `#TN-${FILLER_CODE_START + index}`,
      submittedAt: localTime(0, 16, 10 + index),
      multipleChoiceScore: 5 + (index % 3) * 0.4,
      aiSuggestion: null,
      essayScore: null,
    });
  }
}

async function seedInsights({ db, teacherIds }: SeedContext): Promise<void> {
  for (const [teacher, insight] of Object.entries(TEACHER_INSIGHTS)) {
    const { gaps, ...fields } = insight;
    const teacherId = lookup(teacherIds, teacher);
    await db.teacherInsight.upsert({
      where: { teacherId },
      update: fields,
      create: { teacherId, ...fields },
    });
    for (const [position, gap] of gaps.entries()) {
      await db.knowledgeGap.upsert({
        where: { teacherId_position: { teacherId, position } },
        update: gap,
        create: { teacherId, position, ...gap },
      });
    }
  }
}

export async function seedAssessments(context: SeedContext): Promise<void> {
  for (const item of GRADING_ASSESSMENTS) {
    await seedAssessmentRow(context, item);
  }
  await seedExamAndHomework(context);
  await seedUpcoming(context);
  await seedSubmissions(context);
  await seedInsights(context);
}
