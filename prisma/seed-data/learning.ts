export type SeedTone = "PRIMARY" | "SECONDARY" | "TERTIARY";
export type SeedSubject = "MATH" | "PHYSICS" | "CHEMISTRY" | "ENGLISH";

export const COURSES = [
  {
    slug: "dao-dong-dieu-hoa",
    subjectLabel: "Vật lý 12",
    title: "Dao động điều hòa & Con lắc lò xo",
    instructorLabel: "Cô Mai Hương",
    durationMinutes: 42,
    lessonCount: 18,
    currentLesson: 4,
    progressPercent: 60,
    icon: "science",
    tone: "PRIMARY",
  },
  {
    slug: "writing-task-2",
    subjectLabel: "IELTS 7.0+",
    title: "Writing Task 2: Cấu trúc bài phản biện Argumentative",
    instructorLabel: "Mr. David Wilson",
    durationMinutes: 55,
    lessonCount: 12,
    currentLesson: 4,
    progressPercent: 35,
    icon: "translate",
    tone: "SECONDARY",
  },
  {
    slug: "hop-chat-nito",
    subjectLabel: "Hóa học 12",
    title: "Hợp chất chứa Nitơ & Amin, Amino Axit",
    instructorLabel: "Cô Thu Trang",
    durationMinutes: 30,
    lessonCount: 10,
    currentLesson: 8,
    progressPercent: 78,
    icon: "biotech",
    tone: "TERTIARY",
  },
] as const satisfies readonly {
  slug: string;
  subjectLabel: string;
  title: string;
  instructorLabel: string;
  durationMinutes: number;
  lessonCount: number;
  currentLesson: number;
  progressPercent: number;
  icon: string;
  tone: SeedTone;
}[];

export const MATERIALS = [
  {
    id: "mat-mindmap-do-thi",
    subject: "MATH",
    kind: "Mindmap Đồ thị",
    title: "Sơ đồ tư duy 7 dạng đồ thị hàm số",
    detail: "PDF · 3.4 MB",
    icon: "account_tree",
    tone: "PRIMARY",
    footnote: "Khuyên dùng",
    isRecommended: true,
  },
  {
    id: "mat-bo-de-tu-luyen",
    subject: "MATH",
    kind: "Bộ Đề Tự Luyện",
    title: "150 Câu trắc nghiệm Cực trị có giải chi tiết",
    detail: "PDF + Đáp án chi tiết",
    icon: "quiz",
    tone: "SECONDARY",
    footnote: "Lượt tải: 1,842",
    isRecommended: false,
  },
  {
    id: "mat-so-tay-cong-thuc",
    subject: "MATH",
    kind: "Sổ tay công thức",
    title: "Bộ công thức giải nhanh Đạo hàm 30s",
    detail: "Infographic bỏ túi",
    icon: "draw",
    tone: "TERTIARY",
    footnote: "Cập nhật hôm qua",
    isRecommended: false,
  },
] as const satisfies readonly {
  id: string;
  subject: SeedSubject;
  kind: string;
  title: string;
  detail: string;
  icon: string;
  tone: SeedTone;
  footnote: string;
  isRecommended: boolean;
}[];

const MINUTE = 60;

export const FEATURED_LESSON = {
  id: "les-ung-dung-dao-ham",
  title: "Toán 12: Ứng dụng đạo hàm khảo sát hàm số bậc ba",
  topic: "Chuyên đề Hàm Số 12",
  heading: "Ứng dụng đạo hàm khảo sát hàm số",
  quality: "1080p 60fps",
  handoutName: "Giao_trinh_Dao_ham_Chuyen_sau.pdf",
  durationSeconds: 45 * MINUTE + 10,
  studentPositionSeconds: 18 * MINUTE + 24,
  chapters: [
    {
      slug: "cuc-tri",
      startSeconds: 6 * MINUTE + 20,
      title: "Định lý cực trị cơ bản",
      note: "Lý thuyết then chốt",
      currentNote: "Đang tiếp thu",
    },
    {
      slug: "xet-dau",
      startSeconds: 15 * MINUTE + 45,
      title: "Quy tắc xét dấu f'(x)",
      note: "Lý thuyết then chốt",
      currentNote: "Đang tiếp thu",
    },
    {
      slug: "do-thi",
      startSeconds: 28 * MINUTE + 10,
      title: "Đồ thị dạng tổng quát",
      note: "Khảo sát mẫu",
      currentNote: "Đang tiếp thu",
    },
    {
      slug: "van-dung-cao",
      startSeconds: 39 * MINUTE,
      title: "Vận dụng cao tham số m",
      note: "Phân loại điểm 9+",
      currentNote: "Đang tiếp thu",
    },
  ],
  notes: [
    {
      id: "note-cuc-tri",
      atSeconds: 6 * MINUTE + 40,
      body: "Điều kiện cần: f'(x0) = 0. Điều kiện đủ: f' đổi dấu qua x0.",
    },
    {
      id: "note-xet-dau",
      atSeconds: 16 * MINUTE + 5,
      body: "Quy tắc 1: lập bảng xét dấu f'(x), kết luận cực đại/cực tiểu theo đổi dấu.",
    },
  ],
} as const;

export const TEACHER_LECTURES = [
  {
    id: "les-chuyen-de-04",
    teacher: "ha",
    title: "Chuyên đề 04: Kỹ thuật xử lý cực trị hàm số chứa dấu giá trị tuyệt đối",
    subtitle: "Toán Giải Tích 12 · Cập nhật 2 ngày trước",
    durationSeconds: 38 * MINUTE + 15,
    classKeys: ["12a1", "12a2"],
    viewCount: 284,
    ratingAverage: 4.9,
    ratingCount: 86,
    status: "PUBLISHED",
  },
  {
    id: "les-chuyen-de-05",
    teacher: "ha",
    title: "Chuyên đề 05: Phương pháp tọa độ hóa không gian Oxyz nâng cao",
    subtitle: "Hình học Không gian 12 · Cập nhật 4 ngày trước",
    durationSeconds: 45 * MINUTE,
    classKeys: ["12a1"],
    viewCount: 139,
    ratingAverage: 4.8,
    ratingCount: 42,
    status: "PUBLISHED",
  },
  {
    id: "les-chuyen-de-06",
    teacher: "ha",
    title: "Chuyên đề 06: Tích phân từng phần và ứng dụng tính diện tích hình phẳng",
    subtitle: "Giải Tích 12 · Tạo 1 giờ trước",
    durationSeconds: 29 * MINUTE + 40,
    classKeys: [],
    viewCount: 0,
    ratingAverage: null,
    ratingCount: 0,
    status: "DRAFT",
  },
  {
    id: "les-hinh-hoc-11",
    teacher: "minh",
    title: "Chuyên đề 01: Quan hệ vuông góc trong không gian",
    subtitle: "Hình học 11 · Cập nhật 1 tuần trước",
    durationSeconds: 32 * MINUTE + 10,
    classKeys: ["11b2"],
    viewCount: 57,
    ratingAverage: 4.6,
    ratingCount: 12,
    status: "PUBLISHED",
  },
] as const;

export const BADGE = {
  code: "chien-binh-cham-chi",
  title: "Huy hiệu Chiến binh Chăm chỉ",
  description: "Chỉ còn 1.5 giờ học nữa để mở khóa huy hiệu Tuần 14!",
  weeklyMinutesToEarn: 16 * 60,
} as const;

export const CHAT_SEED = [
  {
    id: "chat-msg-1",
    role: "STUDENT",
    text: "Giải giúp em bài toán này với ạ: Cho hàm số f(x) = x³ - 3x + 2. Tìm tọa độ các điểm cực trị?",
    quote: null,
    highlight: "f(x) = x³ - 3x + 2",
    suggestions: [] as string[],
  },
  {
    id: "chat-msg-2",
    role: "ASSISTANT",
    text: "Chào Minh Anh! Thay vì giải ngay, mình cùng nhớ lại phương pháp chuẩn nhé:",
    quote:
      "Bước đầu tiên để tìm điểm cực trị của một hàm số đa thức là tính gì nhỉ? Hãy thử tính đạo hàm f'(x) xem bằng bao nhiêu nhé!",
    highlight: "f'(x)",
    suggestions: ["💡 Gợi ý tính f'(x)", "📐 Điều kiện cực trị là gì?", "📊 Lập bảng biến thiên"],
  },
] as const;

/** Per-day study seconds for the last 12 days, oldest first (streak 12, last 7 days = 14.5 h). */
export const STUDY_SECONDS_OLDEST_FIRST = [
  3600, 3600, 3600, 3600, 3600, 7200, 7200, 7200, 7200, 7200, 7200, 9000,
] as const;

/** Weekly score series for the parent chart, oldest week first. */
export const SUBJECT_SCORES = [
  { subject: "MATH", scores: [7.0, 7.5, 7.8, 8.2, 8.5, 9.0] },
  { subject: "PHYSICS", scores: [6.8, 7.0, 7.5, 7.5, 8.2, 8.6] },
  { subject: "ENGLISH", scores: [8.0, 8.2, 8.0, 8.5, 8.7, 8.8] },
] as const satisfies readonly { subject: SeedSubject; scores: readonly number[] }[];
