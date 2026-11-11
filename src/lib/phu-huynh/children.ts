import "server-only";
import { childrenOfParent } from "@/lib/auth/access";
import { db } from "@/lib/db";
import { getGivenName } from "@/lib/format/name";
import { CHILDREN_LIMIT } from "./constants";
import type { ChildProfile } from "./types";

export interface ChildRecord {
  readonly profile: ChildProfile;
  readonly weeklyGoalMinutes: number;
  readonly academicYear: string | null;
}

/** The parent's own children in a stable order (oldest profile first, id as tie-break). */
export async function listChildren(parentId: string): Promise<readonly ChildRecord[]> {
  const students = await db.studentProfile.findMany({
    where: childrenOfParent(parentId),
    orderBy: [{ createdAt: "asc" }, { id: "asc" }],
    take: CHILDREN_LIMIT,
    select: {
      id: true,
      studentCode: true,
      weeklyGoalMinutes: true,
      user: { select: { name: true } },
      enrollments: {
        orderBy: { createdAt: "asc" },
        take: 1,
        select: { class: { select: { name: true, academicYear: true } } },
      },
    },
  });

  return students.map((student) => {
    const schoolClass = student.enrollments[0]?.class;
    return {
      profile: {
        id: student.id,
        fullName: student.user.name,
        givenName: getGivenName(student.user.name),
        className: schoolClass?.name ?? "",
        studentCode: student.studentCode,
      },
      weeklyGoalMinutes: student.weeklyGoalMinutes,
      academicYear: schoolClass?.academicYear ?? null,
    };
  });
}

/**
 * Picks the child to show from the parent's own list. An id that is not the parent's child
 * resolves to null, exactly like an id that does not exist, so the response never reveals
 * whether it exists. No extra authorization query: the list is already scoped.
 */
export function selectChild(
  children: readonly ChildRecord[],
  requestedChildId: string | undefined,
): ChildRecord | null {
  if (requestedChildId === undefined) return children[0] ?? null;
  return children.find((child) => child.profile.id === requestedChildId) ?? null;
}
