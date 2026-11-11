import { localTime, lookup, type SeedContext } from "./context";

const MINH_ANH = "minh-anh";
const GIA_BAO = "gia-bao";
const NIGHT_LIMIT_START_MIN = 23 * 60 + 30;

const ACTIVITIES = [
  {
    id: "act-mock-exam",
    kind: "EXAM_COMPLETED",
    title: "Hoàn thành bài thi thử Toán 12",
    at: [0, 15, 30],
    description: [
      { text: "Đạt kết quả " },
      { text: "8.5 / 10 điểm", isEmphasis: true },
      { text: " (34/40 câu đúng). Chủ đề: Khảo sát hàm số nâng cao. Thời gian làm bài: 48 phút." },
    ],
    tags: [
      { label: "Đã chấm chi tiết", tone: "neutral" },
      { label: "Đề thi số 14", tone: "muted" },
    ],
  },
  {
    id: "act-lecture",
    kind: "LECTURE_WATCHED",
    title: 'Xem hết bài giảng "Dao động điều hòa 12"',
    at: [-1, 20, 15],
    description: [
      {
        text: "Thời lượng hoàn thành: 45 phút không gián đoạn. Tốc độ xem trung bình: 1.25x. Ghi chú đã lưu lại: 3 điểm mấu chốt.",
      },
    ],
    tags: [{ label: "Hoàn thành 100% video", tone: "success" }],
  },
  {
    id: "act-ai-tutor",
    kind: "AI_TUTOR",
    title: "Hỏi Trợ lý AI phương pháp giải Vật lý",
    at: [-1, 21, 0],
    description: [
      {
        text: "Tương tác qua 4 câu hỏi định hướng logic về dạng bài Con lắc đơn chịu tác dụng của ngoại lực. Trợ lý Socratic đã hướng dẫn con tự tìm công thức mà không cung cấp đáp án sẵn.",
      },
    ],
    tags: [
      { label: "Tư duy Socratic", tone: "secondary" },
      { label: "Độ hiểu bài: Cao", tone: "muted" },
    ],
  },
] as const;

const TEACHER_NOTE = {
  id: "ptn-minh-anh-tuan-8",
  subject: "Toán học",
  weekLabel: "Tuần 8",
  message:
    "Minh Anh tuần này rất tích cực, chủ động tư duy các bài toán khó dạng vận dụng cao. Con nắm phương pháp đạo hàm rất chắc. Cần rèn thêm sự cẩn thận ở phần tính toán chi tiết và các phép biến đổi đại số cơ bản để tránh mất điểm đáng tiếc.",
} as const;

const GIA_BAO_NOTE = {
  id: "ptn-gia-bao-tuan-8",
  subject: "Toán học",
  weekLabel: "Tuần 8",
  message:
    "Gia Bảo tiếp thu tốt các bài về quan hệ vuông góc. Con nên luyện thêm dạng bài tính góc giữa đường thẳng và mặt phẳng.",
} as const;

async function seedActivity({ db, studentIds }: SeedContext): Promise<void> {
  const studentId = lookup(studentIds, MINH_ANH);

  for (const { id, at, ...entry } of ACTIVITIES) {
    const data = {
      studentId,
      kind: entry.kind,
      title: entry.title,
      description: entry.description,
      tags: entry.tags,
      occurredAt: localTime(at[0], at[1], at[2]),
    };
    await db.activityLog.upsert({ where: { id }, update: data, create: { id, ...data } });
  }
}

async function seedContactBook({
  db,
  studentIds,
  teacherIds,
  parentIds,
}: SeedContext): Promise<void> {
  const acknowledged = {
    studentId: lookup(studentIds, MINH_ANH),
    teacherId: lookup(teacherIds, "ha"),
    subject: TEACHER_NOTE.subject,
    weekLabel: TEACHER_NOTE.weekLabel,
    message: TEACHER_NOTE.message,
    createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000),
    readAt: new Date(),
    acknowledgedAt: new Date(),
    acknowledgedById: lookup(parentIds, "hung"),
  };
  const other = {
    studentId: lookup(studentIds, GIA_BAO),
    teacherId: lookup(teacherIds, "minh"),
    subject: GIA_BAO_NOTE.subject,
    weekLabel: GIA_BAO_NOTE.weekLabel,
    message: GIA_BAO_NOTE.message,
  };
  await db.parentTeacherNote.upsert({
    where: { id: TEACHER_NOTE.id },
    update: acknowledged,
    create: { id: TEACHER_NOTE.id, ...acknowledged },
  });
  await db.parentTeacherNote.upsert({
    where: { id: GIA_BAO_NOTE.id },
    update: other,
    create: { id: GIA_BAO_NOTE.id, ...other },
  });
}

async function seedSettingsAndDevices({ db, studentIds, parentIds }: SeedContext): Promise<void> {
  const links = [
    { parent: "hung", student: MINH_ANH },
    { parent: "lan", student: GIA_BAO },
  ];

  for (const link of links) {
    const parentId = lookup(parentIds, link.parent);
    const studentId = lookup(studentIds, link.student);
    const settings = {
      isNightLimitOn: true,
      nightLimitStartMin: NIGHT_LIMIT_START_MIN,
      isInstantAlertOn: true,
    };
    await db.parentSettings.upsert({
      where: { parentId_studentId: { parentId, studentId } },
      update: settings,
      create: { parentId, studentId, ...settings },
    });
    for (const name of ["iPad Air", "Laptop"]) {
      const id = `dev-${link.student}-${name.toLowerCase().replace(/\s+/g, "-")}`;
      await db.studentDevice.upsert({
        where: { id },
        update: { name },
        create: { id, studentId, name },
      });
    }
  }
}

async function seedNotifications({ db, userIds }: SeedContext): Promise<void> {
  const notifications = [
    {
      id: "ntf-minh-anh-grade",
      userKey: "student:minhAnh",
      kind: "GRADE_PUBLISHED",
      title: "Có điểm kiểm tra mới",
      body: "Bài thi thử Toán 12 đã được chấm: 8.5 / 10 điểm.",
      href: "/hoc-tap",
    },
    {
      id: "ntf-hung-note",
      userKey: "parent:hung",
      kind: "TEACHER_NOTE",
      title: "Nhận xét mới từ cô Nguyễn Thu Hà",
      body: "Cô Hà vừa gửi nhận xét tuần 8 về Minh Anh.",
      href: "/phu-huynh",
    },
  ] as const;

  for (const { id, userKey, ...fields } of notifications) {
    const data = { userId: lookup(userIds, userKey), ...fields };
    await db.notification.upsert({ where: { id }, update: data, create: { id, ...data } });
  }
}

export async function seedParentPortal(context: SeedContext): Promise<void> {
  await seedActivity(context);
  await seedContactBook(context);
  await seedSettingsAndDevices(context);
  await seedNotifications(context);
}
