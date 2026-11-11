import type { Tone } from "@/lib/ui/tone";

/** The subset of shared tones that course and material cards are themed with. */
export type CardTone = Extract<Tone, "primary" | "secondary" | "tertiary">;

export type SubjectKey = "math" | "physics" | "chemistry" | "english";

export type MaterialFilter = "all" | SubjectKey;

export interface WeeklySummary {
  readonly studentFirstName: string;
  readonly weekLabel: string;
  readonly streakDays: number;
  readonly progressPercent: number;
  readonly goalDeltaPercent: number;
  readonly hoursLogged: number;
  readonly hoursTarget: number;
  readonly dueCount: number;
}

export interface LessonChapter {
  readonly id: string;
  readonly startSeconds: number;
  readonly title: string;
  readonly note: string;
  readonly currentNote: string;
}

export interface LessonNote {
  readonly id: string;
  readonly atSeconds: number;
  readonly body: string;
}

export interface FeaturedLesson {
  readonly id: string;
  readonly title: string;
  readonly topic: string;
  readonly heading: string;
  readonly teacher: string;
  readonly quality: string;
  readonly handoutName: string;
  readonly durationSeconds: number;
  readonly positionSeconds: number;
  readonly chapters: readonly LessonChapter[];
  readonly notes: readonly LessonNote[];
}

export interface CourseCard {
  readonly id: string;
  readonly subject: string;
  readonly title: string;
  readonly instructor: string;
  readonly durationMinutes: number;
  readonly progressPercent: number;
  readonly icon: string;
  readonly tone: CardTone;
}

export interface StudyMaterial {
  readonly id: string;
  readonly kind: string;
  readonly title: string;
  readonly detail: string;
  readonly icon: string;
  readonly tone: CardTone;
  readonly subject: SubjectKey;
  readonly footnote: string;
  readonly isRecommended: boolean;
}

export interface MaterialFilterOption {
  readonly value: MaterialFilter;
  readonly label: string;
}

export interface Homework {
  readonly title: string;
  readonly details: string;
  readonly deadlineLabel: string;
  readonly answered: number;
  readonly total: number;
}

export interface BadgeProgress {
  readonly title: string;
  readonly description: string;
}

export type ChatRole = "student" | "assistant";

export interface ChatMessage {
  readonly id: string;
  readonly role: ChatRole;
  readonly text: string;
  readonly time: string;
  readonly quote?: string;
  readonly highlight?: string;
  readonly suggestions?: readonly string[];
}

export interface HocTapOverview {
  readonly summary: WeeklySummary;
  readonly lesson: FeaturedLesson | null;
  readonly courses: readonly CourseCard[];
  readonly courseTotal: number;
  readonly materialFilter: MaterialFilter;
  readonly materialFilters: readonly MaterialFilterOption[];
  readonly materials: readonly StudyMaterial[];
  readonly homework: Homework | null;
  readonly badge: BadgeProgress | null;
  readonly chatThreadId: string | null;
  readonly initialChat: readonly ChatMessage[];
}
