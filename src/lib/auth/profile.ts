import type { Role } from "@/generated/prisma/enums";

interface ProfileRefs {
  readonly studentProfile: { readonly id: string } | null;
  readonly parentProfile: { readonly id: string } | null;
  readonly teacherProfile: { readonly id: string } | null;
}

export class MissingProfileError extends Error {
  constructor(role: Role) {
    super(`User with role ${role} has no matching ${role.toLowerCase()} profile row.`);
    this.name = "MissingProfileError";
  }
}

/**
 * The profile id that matches the user's role. A stray profile of another role must never
 * be used, and a missing matching profile is a data integrity bug that should fail loudly.
 */
export function profileIdForRole(role: Role, profiles: ProfileRefs): string {
  const profile = {
    STUDENT: profiles.studentProfile,
    PARENT: profiles.parentProfile,
    TEACHER: profiles.teacherProfile,
  }[role];

  if (!profile) {
    throw new MissingProfileError(role);
  }
  return profile.id;
}
