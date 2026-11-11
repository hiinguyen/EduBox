import type { ActionResult } from "@/lib/server/action-result";

export type PromptSegmentKind = "text" | "math" | "code";

export interface PromptSegment {
  readonly kind: PromptSegmentKind;
  readonly text: string;
}

export interface QuestionOption {
  readonly id: string;
  readonly label: string;
  readonly text: string;
}

export interface DerivativeGraphFigure {
  readonly kind: "derivative-graph";
  readonly title: string;
  readonly notesTitle: string;
  readonly notes: readonly (readonly PromptSegment[])[];
}

export type QuestionFigure = DerivativeGraphFigure;

export interface Question {
  readonly id: string;
  readonly number: number;
  readonly prompt: readonly PromptSegment[];
  readonly levelLabel: string;
  readonly points: number;
  readonly options: readonly QuestionOption[];
  readonly figure?: QuestionFigure;
}

export interface ExamTool {
  readonly id: string;
  readonly label: string;
  readonly icon: string;
  readonly iconClassName: string;
}

export type SaveAnswersResult = ActionResult<{ readonly savedAt: number }>;
export type SubmitAttemptResult = ActionResult<{ readonly receipt: SubmissionReceipt }>;
export type StartAttemptResult = ActionResult<{ readonly attemptId: string }>;

export interface ExamInfo {
  readonly id: string;
  readonly kindLabel: string;
  readonly proctorStatus: string;
  readonly title: string;
  readonly durationMinutes: number;
  readonly maxScore: number;
  readonly teacherName: string;
}

export type AttemptPhase = "IN_PROGRESS" | "SUBMITTED" | "EXPIRED";

/** An answer row as the server stores it. Times are epoch milliseconds in server time. */
export interface ServerAnswer {
  readonly optionId: string | null;
  readonly isFlagged: boolean;
  readonly answeredAt: number;
}

/** What the student may see after finishing: never a score or a correct answer. */
export interface SubmissionReceipt {
  readonly status: "SUBMITTED" | "EXPIRED";
  readonly submittedAt: number;
  readonly isPendingReview: boolean;
}

export interface ExamSession {
  readonly exam: ExamInfo;
  readonly attemptId: string;
  readonly phase: AttemptPhase;
  /** Absolute deadline set by the server. */
  readonly endsAt: number;
  /** Server clock when the page was rendered, used to correct browser clock skew. */
  readonly serverNow: number;
  readonly currentIndex: number;
  readonly updatedAt: number;
  readonly questions: readonly Question[];
  readonly tools: readonly ExamTool[];
  readonly answers: Readonly<Record<string, ServerAnswer>>;
  readonly submission: SubmissionReceipt | null;
}

/** What a student sees before starting: read only, no attempt exists yet. */
export interface ExamIntro {
  readonly exam: ExamInfo;
  readonly questionCount: number;
  /** Vietnamese label of the due date (for example "Hôm nay 15:30"), or null when there is none. */
  readonly dueLabel: string | null;
  /** The due date has passed, so the exam can no longer be started. */
  readonly isOverdue: boolean;
}

export type ExamPage =
  | { readonly kind: "none" }
  | { readonly kind: "intro"; readonly intro: ExamIntro }
  | { readonly kind: "session"; readonly session: ExamSession };
