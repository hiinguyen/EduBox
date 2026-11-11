import type { GapTone, LessonStatus } from "@/generated/prisma/enums";
import { formatDurationLabel, formatSubmittedAt, formatSubmittedTime, toShortName } from "./labels";
import { parseAiSuggestion } from "./schemas";
import type {
  KnowledgeGap,
  KnowledgeGapTone,
  KnowledgeInsights,
  Lecture,
  SubmissionDetail,
  SubmissionRow,
  Teacher,
} from "./types";

const EMPTY_SUBTITLE = "";

export interface TeacherSource {
  readonly name: string;
  readonly department: string;
  readonly subjectLabel: string;
  readonly termLabel: string;
}

export function toTeacher(source: TeacherSource): Teacher {
  return {
    displayName: source.name,
    shortName: toShortName(source.name),
    department: source.department,
    termLabel: source.termLabel,
    subjectLabel: source.subjectLabel,
  };
}

export interface SubmissionSource {
  readonly id: string;
  readonly code: string;
  readonly multipleChoiceScore: number;
  readonly submittedAt: Date;
  readonly student: { readonly studentCode: string; readonly user: { readonly name: string } };
  readonly grade: { readonly essayScore: number } | null;
}

export function toSubmissionRow(source: SubmissionSource, now: Date): SubmissionRow {
  return {
    id: source.id,
    code: source.code,
    studentName: source.student.user.name,
    studentNumber: source.student.studentCode,
    submittedAtLabel: formatSubmittedAt(source.submittedAt, now),
    multipleChoiceScore: source.multipleChoiceScore,
    essayScore: source.grade?.essayScore ?? null,
  };
}

export interface SubmissionDetailSource extends Omit<SubmissionSource, "grade"> {
  readonly aiSuggestion: unknown;
  readonly grade: {
    readonly essayScore: number;
    readonly feedback: string | null;
    readonly notifiedAt: Date | null;
  } | null;
}

export function toSubmissionDetail(source: SubmissionDetailSource, now: Date): SubmissionDetail {
  return {
    ...toSubmissionRow(source, now),
    submittedTimeLabel: formatSubmittedTime(source.submittedAt),
    feedback: source.grade?.feedback ?? "",
    isParentNotified: source.grade?.notifiedAt != null,
    aiSuggestion: parseAiSuggestion(source.aiSuggestion),
  };
}

export interface LectureSource {
  readonly id: string;
  readonly title: string;
  readonly subtitle: string | null;
  readonly topic: string | null;
  readonly durationSeconds: number;
  readonly viewCount: number;
  readonly ratingAverage: number | null;
  readonly ratingCount: number;
  readonly status: LessonStatus;
  readonly classes: readonly { readonly class: { readonly name: string } }[];
}

export function toLecture(source: LectureSource): Lecture {
  const hasRating = source.ratingAverage !== null && source.ratingCount > 0;
  return {
    id: source.id,
    title: source.title,
    subtitle: source.subtitle ?? source.topic ?? EMPTY_SUBTITLE,
    durationLabel: formatDurationLabel(source.durationSeconds),
    classNames: source.classes.map((item) => item.class.name),
    viewCount: source.viewCount,
    rating:
      hasRating && source.ratingAverage !== null
        ? { average: source.ratingAverage, count: source.ratingCount }
        : null,
    status: source.status === "PUBLISHED" ? "published" : "draft",
  };
}

const GAP_TONES: Readonly<Record<GapTone, KnowledgeGapTone>> = {
  MASTERED: "mastered",
  CONFUSED: "confused",
};

export interface InsightSource {
  readonly scannedSubmissions: number;
  readonly remediationIntro: string;
  readonly remediationLecture: string;
  readonly remediationOutro: string;
  readonly gaps: readonly {
    readonly id: string;
    readonly topic: string;
    readonly percent: number;
    readonly tone: GapTone;
    readonly note: string;
  }[];
}

export function toInsights(source: InsightSource): KnowledgeInsights {
  const gaps: readonly KnowledgeGap[] = source.gaps.map((gap) => ({
    id: gap.id,
    topic: gap.topic,
    percent: gap.percent,
    tone: GAP_TONES[gap.tone],
    note: gap.note,
  }));
  return {
    scannedSubmissions: source.scannedSubmissions,
    gaps,
    remediation: {
      intro: source.remediationIntro,
      lectureTitle: source.remediationLecture,
      outro: source.remediationOutro,
    },
  };
}
