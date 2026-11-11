import "server-only";
import type { SessionUser } from "@/lib/auth/session";
import { loadCourses, loadMaterials } from "./catalog";
import { loadChatHistory } from "./chat-history";
import { loadBadge, loadHomework } from "./homework";
import { loadFeaturedLesson } from "./lesson";
import { loadSummary } from "./summary";
import type { HocTapOverview, MaterialFilter } from "./types";

export async function getHocTapOverview(
  user: SessionUser,
  materialFilter: MaterialFilter = "all",
  now: Date = new Date(),
): Promise<HocTapOverview> {
  const studentId = user.profileId;
  const [summary, lesson, courses, materials, homework, chat] = await Promise.all([
    loadSummary(user, now),
    loadFeaturedLesson(studentId),
    loadCourses(studentId),
    loadMaterials(materialFilter),
    loadHomework(studentId, now),
    loadChatHistory(studentId),
  ]);
  const badge = await loadBadge(studentId, summary.weekSeconds);

  return {
    summary: summary.summary,
    lesson,
    courses: courses.courses,
    courseTotal: courses.total,
    materialFilter,
    materialFilters: materials.filters,
    materials: materials.materials,
    homework,
    badge,
    chatThreadId: chat.threadId,
    initialChat: chat.messages,
  };
}
