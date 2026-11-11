import { SCORE_PRECISION } from "./constants";

export interface GradableQuestion {
  readonly id: string;
  readonly points: number;
}

export interface GradeResult {
  readonly score: number;
  readonly correctCount: number;
  readonly totalCount: number;
}

interface GradeInput {
  readonly questions: readonly GradableQuestion[];
  /** Correct option id per question id. Server only. */
  readonly keys: Readonly<Record<string, string>>;
  /** Selected option id per question id; absent or null means unanswered. */
  readonly answers: Readonly<Record<string, string | null | undefined>>;
}

/** Unanswered questions and questions without a key score zero. */
export function gradeMultipleChoice({ questions, keys, answers }: GradeInput): GradeResult {
  const correct = questions.filter((question) => {
    const keyId = keys[question.id];
    return keyId !== undefined && answers[question.id] === keyId;
  });
  const raw = correct.reduce((sum, question) => sum + question.points, 0);
  return {
    score: Math.round(raw * SCORE_PRECISION) / SCORE_PRECISION,
    correctCount: correct.length,
    totalCount: questions.length,
  };
}

interface AutoGradableInput {
  readonly essayMaxScore: number;
  readonly hasEssayQuestions: boolean;
}

/** Only an assessment with no essay part is finished by the auto grader alone. */
export function isFullyAutoGradable({ essayMaxScore, hasEssayQuestions }: AutoGradableInput) {
  return essayMaxScore === 0 && !hasEssayQuestions;
}
