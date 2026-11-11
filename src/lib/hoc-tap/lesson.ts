import "server-only";
import { lessonsVisibleToStudent, notesOfStudent } from "@/lib/auth/access";
import { db } from "@/lib/db";
import { CHAPTER_LIMIT, LESSON_NOTE_LIMIT } from "./constants";
import type { FeaturedLesson } from "./types";

const lessonSelect = {
  id: true,
  title: true,
  topic: true,
  heading: true,
  instructorLabel: true,
  quality: true,
  handoutName: true,
  durationSeconds: true,
  chapters: {
    orderBy: { startSeconds: "asc" },
    take: CHAPTER_LIMIT,
    select: { id: true, startSeconds: true, title: true, note: true, currentNote: true },
  },
} as const;

async function findCurrentLesson(studentId: string) {
  const resumed = await db.lessonProgress.findFirst({
    where: { studentId, lesson: lessonsVisibleToStudent(studentId) },
    orderBy: { updatedAt: "desc" },
    select: { positionSeconds: true, lesson: { select: lessonSelect } },
  });
  if (resumed) return { lesson: resumed.lesson, positionSeconds: resumed.positionSeconds };

  const lesson = await db.lesson.findFirst({
    where: lessonsVisibleToStudent(studentId),
    orderBy: { createdAt: "desc" },
    select: lessonSelect,
  });
  return lesson ? { lesson, positionSeconds: 0 } : null;
}

export async function loadFeaturedLesson(studentId: string): Promise<FeaturedLesson | null> {
  const current = await findCurrentLesson(studentId);
  if (!current) return null;

  const { lesson, positionSeconds } = current;
  const notes = await db.note.findMany({
    where: { AND: [notesOfStudent(studentId), { lessonId: lesson.id }] },
    orderBy: { atSeconds: "asc" },
    take: LESSON_NOTE_LIMIT,
    select: { id: true, atSeconds: true, body: true },
  });

  return {
    id: lesson.id,
    title: lesson.title,
    topic: lesson.topic ?? "",
    heading: lesson.heading ?? lesson.title,
    teacher: lesson.instructorLabel ?? "",
    quality: lesson.quality ?? "",
    handoutName: lesson.handoutName ?? "",
    durationSeconds: lesson.durationSeconds,
    positionSeconds,
    chapters: lesson.chapters,
    notes,
  };
}
