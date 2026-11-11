import {
  BADGE,
  CHAT_SEED,
  COURSES,
  FEATURED_LESSON,
  MATERIALS,
  STUDY_SECONDS_OLDEST_FIRST,
  SUBJECT_SCORES,
  TEACHER_LECTURES,
} from "../seed-data/learning";
import { localTime, lookup, type SeedContext } from "./context";
import { vnDay, vnWeekStarts } from "./dates";

const MINH_ANH = "minh-anh";
const WEEKS_OF_SCORES = 6;
const STUDENT_VISIBLE_CLASS = "12a1";

async function seedCourses({ db, studentIds }: SeedContext): Promise<void> {
  for (const course of COURSES) {
    const { currentLesson, progressPercent, ...fields } = course;
    const saved = await db.course.upsert({
      where: { slug: course.slug },
      update: fields,
      create: fields,
      select: { id: true },
    });
    const enrollment = { currentLesson, progressPercent };
    await db.courseEnrollment.upsert({
      where: {
        courseId_studentId: { courseId: saved.id, studentId: lookup(studentIds, MINH_ANH) },
      },
      update: enrollment,
      create: { courseId: saved.id, studentId: lookup(studentIds, MINH_ANH), ...enrollment },
    });
  }
}

async function seedMaterials({ db }: SeedContext): Promise<void> {
  for (const material of MATERIALS) {
    await db.material.upsert({ where: { id: material.id }, update: material, create: material });
  }
}

async function seedFeaturedLesson(context: SeedContext): Promise<void> {
  const { db, studentIds, teacherIds, classIds } = context;
  const lesson = FEATURED_LESSON;
  const fields = {
    authorId: lookup(teacherIds, "dung"),
    title: lesson.title,
    topic: lesson.topic,
    heading: lesson.heading,
    instructorLabel: "Thầy Trần Đức Dũng · Tổ trưởng Chuyên môn Toán Chuyên",
    durationSeconds: lesson.durationSeconds,
    quality: lesson.quality,
    handoutName: lesson.handoutName,
    status: "PUBLISHED" as const,
  };
  await db.lesson.upsert({
    where: { id: lesson.id },
    update: fields,
    create: { id: lesson.id, ...fields },
  });
  await db.lessonClass.createMany({
    data: [{ lessonId: lesson.id, classId: lookup(classIds, STUDENT_VISIBLE_CLASS) }],
    skipDuplicates: true,
  });
  for (const chapter of lesson.chapters) {
    await db.lessonChapter.upsert({
      where: { lessonId_slug: { lessonId: lesson.id, slug: chapter.slug } },
      update: chapter,
      create: { lessonId: lesson.id, ...chapter },
    });
  }
  const studentId = lookup(studentIds, MINH_ANH);
  const progress = { positionSeconds: lesson.studentPositionSeconds };
  await db.lessonProgress.upsert({
    where: { studentId_lessonId: { studentId, lessonId: lesson.id } },
    update: progress,
    create: { studentId, lessonId: lesson.id, ...progress },
  });
  for (const note of lesson.notes) {
    const data = { studentId, lessonId: lesson.id, atSeconds: note.atSeconds, body: note.body };
    await db.note.upsert({
      where: { id: note.id },
      update: data,
      create: { id: note.id, ...data },
    });
  }
}

async function seedTeacherLectures({ db, teacherIds, classIds }: SeedContext): Promise<void> {
  for (const lecture of TEACHER_LECTURES) {
    const { id, teacher, classKeys, ...rest } = lecture;
    const fields = { ...rest, authorId: lookup(teacherIds, teacher) };
    await db.lesson.upsert({ where: { id }, update: fields, create: { id, ...fields } });
    await db.lessonClass.createMany({
      data: classKeys.map((key) => ({ lessonId: id, classId: lookup(classIds, key) })),
      skipDuplicates: true,
    });
  }
}

async function seedChat({ db, studentIds }: SeedContext): Promise<void> {
  const studentId = lookup(studentIds, MINH_ANH);
  const threadId = "chat-thread-minh-anh";
  await db.chatThread.upsert({
    where: { id: threadId },
    update: {},
    create: { id: threadId, studentId, title: "Cực trị hàm số bậc ba" },
  });
  for (const [index, message] of CHAT_SEED.entries()) {
    const { id, ...fields } = message;
    const data = {
      ...fields,
      suggestions: [...fields.suggestions],
      createdAt: localTime(0, 14, 32 + index),
    };
    await db.chatMessage.upsert({
      where: { id },
      update: data,
      create: { id, threadId, ...data },
    });
  }
}

/**
 * Replaces the demo student's progress rows so earlier seeds that wrote wrong dates
 * (for example non-Monday week starts) never linger next to the corrected ones.
 */
async function seedProgress({ db, studentIds }: SeedContext): Promise<void> {
  const studentId = lookup(studentIds, MINH_ANH);
  const lastIndex = STUDY_SECONDS_OLDEST_FIRST.length - 1;
  const weekStarts = vnWeekStarts(WEEKS_OF_SCORES);

  await db.$transaction([
    db.studyDay.deleteMany({ where: { studentId } }),
    db.subjectWeekScore.deleteMany({ where: { studentId } }),
    db.studyDay.createMany({
      data: STUDY_SECONDS_OLDEST_FIRST.map((studiedSeconds, index) => ({
        studentId,
        day: vnDay(index - lastIndex),
        studiedSeconds,
      })),
    }),
    db.subjectWeekScore.createMany({
      data: SUBJECT_SCORES.flatMap(({ subject, scores }) =>
        scores.map((score, index) => {
          const weekStart = weekStarts[index];
          if (!weekStart) {
            throw new Error(`Seed has more scores than weeks for ${subject}`);
          }
          return { studentId, subject, weekStart, score };
        }),
      ),
    }),
  ]);
}

async function seedBadge({ db }: SeedContext): Promise<void> {
  await db.badge.upsert({ where: { code: BADGE.code }, update: BADGE, create: BADGE });
}

export async function seedLearning(context: SeedContext): Promise<void> {
  await seedCourses(context);
  await seedMaterials(context);
  await seedFeaturedLesson(context);
  await seedTeacherLectures(context);
  await seedChat(context);
  await seedProgress(context);
  await seedBadge(context);
}
