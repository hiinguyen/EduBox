import "server-only";
import type { CurrentUser, UserRole } from "@/lib/current-user";
import { db } from "@/lib/db";
import { getInitials } from "@/lib/format/initials";
import { requireUser } from "./session";

const ROLE_LABELS = {
  STUDENT: "Học sinh",
  PARENT: "Phụ huynh",
  TEACHER: "Giáo viên",
} as const;

const INITIAL_LETTERS = 2;
const DESCRIPTION_SEPARATOR = " · ";

async function describeStudent(profileId: string): Promise<string> {
  const enrollment = await db.enrollment.findFirst({
    where: { studentId: profileId },
    orderBy: { createdAt: "asc" },
    select: { class: { select: { name: true } } },
  });
  const label = ROLE_LABELS.STUDENT;
  return enrollment ? `Lớp ${enrollment.class.name}${DESCRIPTION_SEPARATOR}${label}` : label;
}

async function describeTeacher(profileId: string): Promise<string> {
  const profile = await db.teacherProfile.findUnique({
    where: { id: profileId },
    select: { subjectLabel: true },
  });
  const label = ROLE_LABELS.TEACHER;
  return profile ? `${label}${DESCRIPTION_SEPARATOR}${profile.subjectLabel}` : label;
}

const DESCRIBERS = {
  STUDENT: describeStudent,
  TEACHER: describeTeacher,
  PARENT: async () => ROLE_LABELS.PARENT,
} as const satisfies Record<UserRole, (profileId: string) => Promise<string>>;

/** Builds the app shell's user from the signed-in session. Redirects to /dang-nhap if there is none. */
export async function getShellUser(): Promise<CurrentUser> {
  const user = await requireUser();
  const description = await DESCRIBERS[user.role](user.profileId);
  const initials = getInitials(user.name, INITIAL_LETTERS, { shouldSkipHonorific: true });

  return { name: user.name, initials, role: user.role, description };
}
