import { MS_PER_MINUTE } from "@/lib/format/time";

export const SUBMISSIONS_PAGE_SIZE = 10;
export const LECTURES_PAGE_SIZE = 5;

/** Upper bounds for lists that are not paginated, so no query is unbounded. */
export const MAX_CLASSES = 50;
export const MAX_ASSESSMENTS = 100;
export const MAX_GAPS = 10;
export const MAX_PARENTS_PER_STUDENT = 10;
export const MAX_CLASSES_PER_LECTURE = 10;

export const MAX_FEEDBACK_LENGTH = 1000;
export const SCORE_STEP = 0.25;
export const MAX_ID_LENGTH = 64;

export const GRADE_RATE_LIMIT = 60;
export const GRADE_RATE_WINDOW_MS = MS_PER_MINUTE;
export const GRADE_RATE_KEY_PREFIX = "teacher-grade";

export const WORKSPACE_PATH = "/giao-vien";
export const PARENT_PORTAL_PATH = "/phu-huynh";

export const QUERY_KEYS = {
  classId: "lop",
  assessmentId: "bai",
  page: "trang",
  submissionId: "bai-nop",
  lecturePage: "bai-giang",
} as const;
