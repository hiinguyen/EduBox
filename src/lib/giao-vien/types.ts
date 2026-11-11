import type { Pagination } from "./pagination";
import type { AiGradingSuggestion } from "./schemas";

export type LectureStatus = "published" | "draft";
export type KnowledgeGapTone = "mastered" | "confused";

export interface Teacher {
  readonly displayName: string;
  /** Form of address used in running text, e.g. "cô Hà". */
  readonly shortName: string;
  readonly department: string;
  readonly termLabel: string;
  readonly subjectLabel: string;
}

export interface ClassOption {
  readonly id: string;
  readonly name: string;
  readonly trackLabel: string;
  readonly subjectLabel: string;
}

export interface AssessmentOption {
  readonly id: string;
  readonly title: string;
}

export interface Assessment extends AssessmentOption {
  readonly essayPrompt: string;
  readonly multipleChoiceMaxScore: number;
  readonly essayMaxScore: number;
}

export interface SubmissionRow {
  readonly id: string;
  readonly code: string;
  readonly studentName: string;
  readonly studentNumber: string;
  readonly submittedAtLabel: string;
  readonly multipleChoiceScore: number;
  readonly essayScore: number | null;
}

export interface SubmissionDetail extends SubmissionRow {
  readonly submittedTimeLabel: string;
  readonly feedback: string;
  readonly isParentNotified: boolean;
  readonly aiSuggestion: AiGradingSuggestion | null;
}

export interface Lecture {
  readonly id: string;
  readonly title: string;
  readonly subtitle: string;
  readonly durationLabel: string;
  readonly classNames: readonly string[];
  readonly viewCount: number;
  readonly rating: { readonly average: number; readonly count: number } | null;
  readonly status: LectureStatus;
}

export interface LectureLibraryData {
  readonly items: readonly Lecture[];
  readonly pagination: Pagination;
  readonly total: number;
  readonly approved: number;
}

export interface KnowledgeGap {
  readonly id: string;
  readonly topic: string;
  readonly percent: number;
  readonly tone: KnowledgeGapTone;
  readonly note: string;
}

export interface KnowledgeInsights {
  readonly scannedSubmissions: number;
  readonly gaps: readonly KnowledgeGap[];
  readonly remediation: {
    readonly intro: string;
    readonly lectureTitle: string;
    readonly outro: string;
  };
}

export interface CompletionRate {
  readonly percent: number;
  readonly submitted: number;
  readonly expected: number;
}

export interface AverageScore {
  readonly score: number;
  readonly sourceTitle: string;
}

export interface TeacherStats {
  readonly totalStudents: number;
  readonly classNames: readonly string[];
  readonly pendingSubmissions: number;
  readonly gradingDeadlineLabel: string | null;
  readonly completion: CompletionRate | null;
  readonly average: AverageScore | null;
}

export interface GradingSelection {
  readonly classId: string;
  readonly assessmentId: string | null;
}

/** Everything the grading board shows; the rows are one page of the selected assessment. */
export interface GradingBoardData {
  readonly classes: readonly ClassOption[];
  readonly assessments: readonly Assessment[];
  readonly selection: GradingSelection;
  readonly classRoomName: string;
  readonly subjectLabel: string;
  readonly rows: readonly SubmissionRow[];
  readonly pagination: Pagination;
  readonly selected: SubmissionDetail | null;
  readonly nextPendingId: string | null;
  /** Pending submissions of the selected assessment, not only of the visible page. */
  readonly pendingCount: number;
}

export interface TeacherWorkspace {
  readonly teacher: Teacher;
  readonly stats: TeacherStats;
  readonly lectures: LectureLibraryData;
  readonly grading: GradingBoardData | null;
  readonly insights: KnowledgeInsights | null;
}
