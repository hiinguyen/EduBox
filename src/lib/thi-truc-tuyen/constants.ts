import { MS_PER_MINUTE, MS_PER_SECOND } from "../format/time";

/** Client waits this long after the last change before sending a batch to the server. */
export const SAVE_DEBOUNCE_MS = 1_500;

/** Delay before the client retries a failed save or submit. */
export const SAVE_RETRY_DELAY_MS = 5_000;

/** The server still takes final answers this long after `endsAt`, to absorb network latency. */
export const SUBMIT_GRACE_MS = 30 * MS_PER_SECOND;

/** Upper bound of questions in one exam; also caps every list query and answer batch. */
export const MAX_QUESTIONS_PER_EXAM = 200;

export const SUBMIT_RATE_LIMIT = { limit: 10, windowMs: MS_PER_MINUTE } as const;
export const SUBMIT_RATE_LIMIT_KEY_PREFIX = "exam-submit";

/** Autosave is debounced to one call per 1.5 s, so a regular session stays far below this. */
export const SAVE_RATE_LIMIT = { limit: 60, windowMs: MS_PER_MINUTE } as const;
export const SAVE_RATE_LIMIT_KEY_PREFIX = "exam-save";

export const START_RATE_LIMIT = { limit: 10, windowMs: MS_PER_MINUTE } as const;
export const START_RATE_LIMIT_KEY_PREFIX = "exam-start";

/** Upper bound of attempts finalised by one lazy or scheduled expiry pass. */
export const DEFAULT_EXPIRY_BATCH_SIZE = 50;

export const SCORE_SCALE = 10;

export const DEFAULT_KIND_LABEL = "Chính thức";
export const DEFAULT_PROCTOR_STATUS = "Đang kết nối giám thị trực tuyến";

/** Scores are stored with two decimals; this removes float noise such as 0.4 * 3. */
export const SCORE_PRECISION = 100;

export const SUBMISSION_CODE_PREFIX = "#TN-";
export const SUBMISSION_CODE_MIN = 1_000;
export const SUBMISSION_CODE_RANGE = 9_000;
export const SUBMISSION_CODE_ATTEMPTS = 5;
/** The unique index on (assessmentId, code); a clash on it is the only retryable conflict. */
export const SUBMISSION_CODE_COLUMN = "code";

export const MAX_ASSESSMENT_ID_LENGTH = 64;
