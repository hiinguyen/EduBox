import { MS_PER_MINUTE } from "@/lib/format/time";

export const SECONDS_PER_HOUR = 3600;
export const MINUTES_PER_HOUR = 60;
export const DAYS_PER_WEEK = 7;

/** Hard caps so no list query is unbounded. */
export const CHILDREN_LIMIT = 20;
export const ACTIVITY_LIMIT = 5;
export const UPCOMING_LIMIT = 5;
export const DEVICES_LIMIT = 5;
export const RECENT_GRADES_LIMIT = 50;
export const STUDY_LOOKBACK_DAYS = 60;
export const CHART_WEEKS = 6;

/** Score statistics cover recently graded work only. */
export const GRADE_WINDOW_DAYS = 30;

/** Weekly question count that fills the AI stat bar. */
export const AI_QUESTIONS_WEEKLY_TARGET = 40;
export const SCORE_SCALE = 10;
export const BADGE_RECENT_DAYS = DAYS_PER_WEEK;

/** Deadlines closer than this are flagged urgent and shown as a countdown. */
export const URGENT_WINDOW_HOURS = 24;

export const DEFAULT_NIGHT_LIMIT_START_MIN = 23 * MINUTES_PER_HOUR + 30;

/** Rate limits for the parent write actions (per user). */
export const WRITE_RATE_LIMIT = { limit: 30, windowMs: MS_PER_MINUTE } as const;
export const SETTING_RATE_KEY_PREFIX = "parent-setting";
export const NOTE_ACK_RATE_KEY_PREFIX = "parent-note-ack";
