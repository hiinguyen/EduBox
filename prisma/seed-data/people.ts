// Demo people. Display names mirror the screen fixtures; emails use the reserved .test TLD.
export const DEMO_EMAIL_DOMAIN = "edubox.test";

export interface SeedAccount {
  readonly key: string;
  readonly name: string;
  readonly email: string;
}

export const STUDENT_ACCOUNTS = {
  minhAnh: { key: "minh-anh", name: "Nguyễn Minh Anh", email: `minh.anh@${DEMO_EMAIL_DOMAIN}` },
  giaBao: { key: "gia-bao", name: "Trần Gia Bảo", email: `gia.bao@${DEMO_EMAIL_DOMAIN}` },
} as const satisfies Record<string, SeedAccount>;

export const PARENT_ACCOUNTS = {
  hung: { key: "hung", name: "Bác Nguyễn Văn Hùng", email: `van.hung@${DEMO_EMAIL_DOMAIN}` },
  lan: { key: "lan", name: "Chị Trần Thị Lan", email: `thi.lan@${DEMO_EMAIL_DOMAIN}` },
} as const satisfies Record<string, SeedAccount>;

export interface SeedTeacher extends SeedAccount {
  readonly department: string;
  readonly subjectLabel: string;
}

export const TEACHER_ACCOUNTS = {
  ha: {
    key: "ha",
    name: "Cô Nguyễn Thu Hà",
    email: `thu.ha@${DEMO_EMAIL_DOMAIN}`,
    department: "Tổ Toán - THPT Chuyên",
    subjectLabel: "Toán học 12",
  },
  minh: {
    key: "minh",
    name: "Thầy Trần Quang Minh",
    email: `quang.minh@${DEMO_EMAIL_DOMAIN}`,
    department: "Tổ Toán - THPT Chuyên",
    subjectLabel: "Toán học 11",
  },
  dung: {
    key: "dung",
    name: "Thầy Trần Đức Dũng",
    email: `duc.dung@${DEMO_EMAIL_DOMAIN}`,
    department: "Tổ trưởng Chuyên môn Toán Chuyên",
    subjectLabel: "Toán học 12",
  },
} as const satisfies Record<string, SeedTeacher>;

export interface SeedClass {
  readonly key: string;
  readonly name: string;
  readonly trackLabel: string;
  readonly subjectLabel: string;
  readonly studentCount: number;
  readonly teacherKeys: readonly (keyof typeof TEACHER_ACCOUNTS)[];
}

export const TERM_LABEL = "Học kỳ II · 2024";
export const ACADEMIC_YEAR = "2024-2025";

export const CLASSES: readonly SeedClass[] = [
  {
    key: "12a1",
    name: "12A1",
    trackLabel: "Toán Chuyên",
    subjectLabel: "Toán học 12 (Nâng cao)",
    studentCount: 48,
    teacherKeys: ["ha", "dung"],
  },
  {
    key: "12a2",
    name: "12A2",
    trackLabel: "Toán Tự Nhiên",
    subjectLabel: "Toán học 12 (Nâng cao)",
    studentCount: 47,
    teacherKeys: ["ha"],
  },
  {
    key: "12d1",
    name: "12D1",
    trackLabel: "Toán Xã Hội",
    subjectLabel: "Toán học 12 (Cơ bản)",
    studentCount: 47,
    teacherKeys: ["ha"],
  },
  {
    key: "11b2",
    name: "11B2",
    trackLabel: "Toán Chuyên",
    subjectLabel: "Toán học 11 (Nâng cao)",
    studentCount: 36,
    teacherKeys: ["minh"],
  },
];

export interface SeedNamedStudent {
  readonly key: string;
  readonly name: string;
  readonly code: string;
  readonly classKey: string;
}

/** Students who appear by name in teacher fixtures. They have no login. */
export const NAMED_STUDENTS: readonly SeedNamedStudent[] = [
  { key: "nam", name: "Lê Hoàng Nam", code: "120148", classKey: "12a1" },
  { key: "linh", name: "Trần Khánh Linh", code: "120152", classKey: "12a1" },
  { key: "huy", name: "Phạm Quốc Huy", code: "120155", classKey: "12a1" },
  { key: "duyen", name: "Đỗ Mỹ Duyên", code: "120139", classKey: "12a1" },
  { key: "khoa", name: "Vũ Anh Khoa", code: "110021", classKey: "11b2" },
];

export const STUDENT_CODES = {
  "minh-anh": { code: "ES-2024-8892", classKey: "12a1" },
  "gia-bao": { code: "ES-2024-7310", classKey: "11b2" },
} as const;

export const PARENT_LINKS = [
  { parent: "hung", student: "minh-anh" },
  { parent: "lan", student: "gia-bao" },
] as const;
