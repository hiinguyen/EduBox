import type { SeedSubject } from "./learning";

const ESSAY_PROMPT_Q14 = "Ảnh chụp lời giải câu 14 - Tìm m để hàm số đạt cực tiểu tại x = 2";
const MULTIPLE_CHOICE_MAX = 6;
const ESSAY_MAX = 4;
export const MAX_SCORE = 10;

export interface SeedAssessment {
  readonly id: string;
  readonly classKey: string;
  readonly creator: "ha" | "minh" | "dung";
  readonly kind: "HOMEWORK" | "QUIZ" | "EXAM";
  readonly subject: SeedSubject;
  readonly title: string;
  readonly essayPrompt: string | null;
  readonly multipleChoiceMaxScore: number;
  readonly essayMaxScore: number;
}

const MIXED = { multipleChoiceMaxScore: MULTIPLE_CHOICE_MAX, essayMaxScore: ESSAY_MAX } as const;

/** Teacher grading fixtures: mixed multiple choice and essay assessments. */
export const GRADING_ASSESSMENTS: readonly SeedAssessment[] = [
  {
    id: "asm-kt45-cuc-tri",
    classKey: "12a1",
    creator: "ha",
    kind: "QUIZ",
    subject: "MATH",
    title: "KT 45p: Cực trị & Tiệm cận hàm số",
    essayPrompt: ESSAY_PROMPT_Q14,
    ...MIXED,
  },
  {
    id: "asm-btvn-dao-ham",
    classKey: "12a1",
    creator: "ha",
    kind: "HOMEWORK",
    subject: "MATH",
    title: "Bài tập về nhà: Ứng dụng đạo hàm",
    essayPrompt: ESSAY_PROMPT_Q14,
    ...MIXED,
  },
  {
    id: "asm-thi-thu-lan-1",
    classKey: "12a1",
    creator: "ha",
    kind: "EXAM",
    subject: "MATH",
    title: "Thi thử THPT QG Lần 1",
    essayPrompt: ESSAY_PROMPT_Q14,
    ...MIXED,
  },
  {
    id: "asm-kt45-cuc-tri-12a2",
    classKey: "12a2",
    creator: "ha",
    kind: "QUIZ",
    subject: "MATH",
    title: "KT 45p: Cực trị & Tiệm cận hàm số",
    essayPrompt: ESSAY_PROMPT_Q14,
    ...MIXED,
  },
  {
    id: "asm-kt45-cuc-tri-12d1",
    classKey: "12d1",
    creator: "ha",
    kind: "QUIZ",
    subject: "MATH",
    title: "KT 45p: Cực trị & Tiệm cận hàm số",
    essayPrompt: ESSAY_PROMPT_Q14,
    ...MIXED,
  },
  {
    id: "asm-kt45-quan-he-vuong-goc",
    classKey: "11b2",
    creator: "minh",
    kind: "QUIZ",
    subject: "MATH",
    title: "KT 45p: Quan hệ vuông góc",
    essayPrompt: "Ảnh chụp lời giải câu 12",
    ...MIXED,
  },
];

export const EXAM = {
  id: "asm-exam-ham-so",
  title: "Kiểm tra Đánh giá Năng lực Toán 12 - Chuyên đề Hàm số & Ứng dụng",
  kindLabel: "Chính thức · Học kỳ I",
  proctorStatus: "Đang kết nối giám thị trực tuyến",
  durationMinutes: 50,
} as const;

export const HOMEWORK_06 = {
  id: "asm-phieu-bai-tap-06",
  title: "Phiếu bài tập số 06: Đạo hàm & Tiếp tuyến",
  subtitle: "Lớp 12A1 · 25 câu trắc nghiệm (Dự kiến 30 phút)",
  durationMinutes: 30,
} as const;

export const UPCOMING = [
  {
    id: "asm-hoa-huu-co",
    kind: "HOMEWORK",
    subject: "CHEMISTRY",
    title: "Hạn nộp bài tập Hóa học hữu cơ",
    subtitle: "Chuyên đề Este - Lipit (15 câu trắc nghiệm)",
    dueInDays: 1,
    dueHour: 21,
    isOnline: true,
  },
  {
    id: "asm-khao-sat-thang-10",
    kind: "EXAM",
    subject: "MATH",
    title: "Thi khảo sát chất lượng tháng 10",
    subtitle: "Toán, Vật lý, Hóa học (Trực tiếp tại trường)",
    dueInDays: 3,
    dueHour: 7,
    isOnline: false,
  },
] as const;

const NAM_FEEDBACK =
  "Em nắm chắc phương pháp giải cực trị rất tốt. Lưu ý kiểm tra kỹ dấu khi phân tích nhân tử ở dòng 4 câu 14 để không mất điểm đáng tiếc nhé!";

export interface SeedSubmission {
  readonly studentKey: string;
  readonly assessmentId: string;
  readonly code: string;
  readonly time: readonly [number, number, number];
  readonly multipleChoiceScore: number;
  readonly essayScore: number | null;
  readonly aiSuggestion: null | {
    readonly comment: string;
    readonly suggestedScore: number;
    readonly feedbackDraft: string;
  };
}

export const NAMED_SUBMISSIONS: readonly SeedSubmission[] = [
  {
    studentKey: "nam",
    assessmentId: "asm-kt45-cuc-tri",
    code: "#TN-982",
    time: [14, 22, 18],
    multipleChoiceScore: 6,
    essayScore: null,
    aiSuggestion: {
      comment:
        "Học sinh nắm chắc phương pháp giải cực trị, lập luận chặt chẽ. Tuy nhiên, em tính toán nhầm ở bước biến đổi dấu câu 14 (dòng thứ 4 từ trên xuống, nhầm dấu khi phân tích nhân tử khiến giá trị m = -1 bị loại sai).",
      suggestedScore: 3.25,
      feedbackDraft: NAM_FEEDBACK,
    },
  },
  {
    studentKey: "linh",
    assessmentId: "asm-kt45-cuc-tri",
    code: "#TN-983",
    time: [15, 10, 40],
    multipleChoiceScore: 5.6,
    essayScore: 3.5,
    aiSuggestion: null,
  },
  {
    studentKey: "huy",
    assessmentId: "asm-kt45-cuc-tri",
    code: "#TN-984",
    time: [15, 45, 3],
    multipleChoiceScore: 5.2,
    essayScore: null,
    aiSuggestion: null,
  },
  {
    studentKey: "duyen",
    assessmentId: "asm-kt45-cuc-tri",
    code: "#TN-985",
    time: [16, 2, 51],
    multipleChoiceScore: 6,
    essayScore: 3.8,
    aiSuggestion: null,
  },
  {
    studentKey: "khoa",
    assessmentId: "asm-kt45-quan-he-vuong-goc",
    code: "#TN-701",
    time: [9, 30, 12],
    multipleChoiceScore: 5.8,
    essayScore: null,
    aiSuggestion: null,
  },
];

/** Extra pending submissions so the first quiz shows the 18 pending the teacher fixture expects. */
export const FILLER_PENDING_COUNT = 16;
export const FILLER_CODE_START = 986;

export const TEACHER_INSIGHTS = {
  ha: {
    scannedSubmissions: 42,
    remediationIntro: "Nên mở 1 video ngắn 15 phút:",
    remediationLecture: "Các bẫy tiệm cận đứng khi tử và mẫu có nghiệm chung",
    remediationOutro: "và giao kèm 5 câu trắc nghiệm nhanh cho nhóm 12 em chưa đạt chuẩn.",
    gaps: [
      {
        topic: "Khảo sát & Cực trị hàm đa thức bậc ba",
        percent: 68,
        tone: "MASTERED",
        note: "Hầu hết các em thành thạo bảng biến thiên và nghiệm đạo hàm bậc 2.",
      },
      {
        topic: "Nhận diện tiệm cận đứng & tiệm cận ngang đồ thị phân thức",
        percent: 28,
        tone: "CONFUSED",
        note: "Lỗi phổ biến: Quên đối chiếu nghiệm của mẫu với điều kiện triệt tiêu của tử số.",
      },
    ],
  },
  minh: {
    scannedSubmissions: 1,
    remediationIntro: "Chưa đủ dữ liệu để gợi ý bài giảng bổ trợ:",
    remediationLecture: "Chờ thêm bài nộp",
    remediationOutro: "từ lớp của thầy.",
    gaps: [],
  },
} as const;
