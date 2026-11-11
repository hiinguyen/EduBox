import { MS_PER_DAY, MS_PER_MINUTE } from "@/lib/format/time";

export const MAX_CHAT_LENGTH = 500;
export const MAX_NOTE_LENGTH = 1_000;
export const MAX_LESSON_SECONDS = 24 * 60 * 60;

export const CHAT_HISTORY_VIEW_LIMIT = 30;
export const CHAT_CONTEXT_LIMIT = 12;
export const CHAT_RATE_LIMIT = 20;
export const CHAT_RATE_WINDOW_MS = MS_PER_MINUTE;
export const CHAT_DAILY_LIMIT = 200;
export const CHAT_DAILY_WINDOW_MS = MS_PER_DAY;
export const CHAT_GLOBAL_RATE_LIMIT = 600;
export const CHAT_GLOBAL_WINDOW_MS = MS_PER_MINUTE;
export const CHAT_MAX_BODY_BYTES = 8_192;

export const NOTE_RATE_LIMIT = 30;
export const NOTE_RATE_WINDOW_MS = MS_PER_MINUTE;
export const MAX_NOTES_PER_LESSON = 50;

/** Study time credited by one progress save never exceeds this, so seeking cannot fake hours. */
export const MAX_CREDITED_SECONDS_PER_UPDATE = 5 * 60;

export const COURSE_CARD_LIMIT = 3;
export const CHAPTER_LIMIT = 20;
export const LESSON_NOTE_LIMIT = MAX_NOTES_PER_LESSON;
export const MATERIAL_LIMIT = 60;
export const STUDY_DAY_LOOKBACK = 60;
