import type { Tone } from "@/lib/ui/tone";

/** Tones the score chart has line styles for. */
export type SeriesTone = Extract<Tone, "primary" | "secondary" | "tertiary">;

export interface TextSegment {
  readonly text: string;
  readonly isEmphasis?: boolean;
}

export interface ParentProfile {
  readonly displayName: string;
}

export interface ChildProfile {
  readonly id: string;
  readonly fullName: string;
  readonly className: string;
  readonly studentCode: string;
  readonly givenName: string;
}

export type StatId = "online-time" | "lectures" | "average-score" | "ai-questions";

export type StatDetail =
  | { readonly kind: "trend"; readonly text: string }
  | { readonly kind: "verified"; readonly prefix: string; readonly emphasis: string }
  | { readonly kind: "badge"; readonly text: string }
  | { readonly kind: "note"; readonly text: string };

export interface WeeklyStat {
  readonly id: StatId;
  readonly label: string;
  readonly icon: string;
  readonly value: string;
  readonly unit: string;
  readonly detail: StatDetail;
  readonly progressPercent: number;
}

export interface ScoreSeries {
  readonly id: string;
  readonly label: string;
  readonly tone: SeriesTone;
  readonly scores: readonly number[];
}

export interface ProgressReport {
  readonly subtitle: string;
  readonly weekLabels: readonly string[];
  readonly series: readonly ScoreSeries[];
  readonly highlightedSeriesId: string;
  readonly insight: { readonly lead: string; readonly body: string };
}

export interface Tag {
  readonly label: string;
  readonly tone: Tone;
}

export type ActivityTone = "primary" | "secondary" | "neutral";

export interface ActivityEntry {
  readonly id: string;
  readonly icon: string;
  readonly tone: ActivityTone;
  readonly title: string;
  readonly timeLabel: string;
  readonly description: readonly TextSegment[];
  readonly tags: readonly Tag[];
}

export interface TeacherNote {
  readonly id: string;
  readonly isAcknowledged: boolean;
  readonly teacherName: string;
  readonly subject: string;
  readonly role: string;
  readonly sentAgo: string;
  readonly weekLabel: string;
  readonly message: string;
}

export type DeadlineBadge =
  | { readonly kind: "countdown"; readonly value: string; readonly caption: string }
  | { readonly kind: "icon"; readonly icon: string; readonly caption: string };

export interface UpcomingTask {
  readonly id: string;
  readonly title: string;
  readonly subtitle: string;
  readonly dueLabel: string;
  readonly isUrgent: boolean;
  readonly badge: DeadlineBadge;
}

export interface CompanionSetting {
  readonly id: string;
  readonly icon: string;
  readonly tone: Tone;
  readonly title: string;
  readonly description: string;
  readonly isEnabled: boolean;
}

export interface LinkedDevices {
  readonly label: string;
  readonly actionLabel: string;
}

export interface EffortHighlight {
  readonly eyebrow: string;
  readonly title: string;
  readonly body: string;
}

export interface ChildDashboardData {
  readonly stats: readonly WeeklyStat[];
  readonly progress: ProgressReport | null;
  readonly activity: readonly ActivityEntry[];
  readonly teacherNote: TeacherNote | null;
  readonly upcoming: readonly UpcomingTask[];
  readonly settings: readonly CompanionSetting[];
  readonly linkedDevices: LinkedDevices;
  readonly effort: EffortHighlight;
}

export interface ParentDashboard extends ChildDashboardData {
  readonly parent: ParentProfile;
  readonly academicYear: string;
  readonly children: readonly ChildProfile[];
  readonly selectedChild: ChildProfile;
}
