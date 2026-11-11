import "server-only";
import { cache } from "react";
import { notFound, redirect } from "next/navigation";
import type { Role } from "@/generated/prisma/enums";
import { db } from "@/lib/db";
import { auth } from "./auth";
import { profileIdForRole } from "./profile";
import { buildSignInUrl } from "./route-access";

/**
 * The authenticated user as the domain code sees it.
 * `profileId` is the id of the role's profile row (StudentProfile, ParentProfile or
 * TeacherProfile id) and is what every access.ts helper expects.
 */
export interface SessionUser {
  readonly id: string;
  readonly role: Role;
  readonly name: string;
  readonly email: string;
  readonly profileId: string;
}

export type ActionAuthErrorCode = "UNAUTHENTICATED" | "FORBIDDEN";

export interface ActionAuthError {
  readonly code: ActionAuthErrorCode;
  readonly message: string;
}

export type ActionAuthResult =
  | { readonly ok: true; readonly user: SessionUser }
  | { readonly ok: false; readonly error: ActionAuthError };

const UNAUTHENTICATED_MESSAGE = "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.";
const FORBIDDEN_MESSAGE = "Bạn không có quyền thực hiện thao tác này.";

function toRoleList(role: Role | readonly Role[]): readonly Role[] {
  return typeof role === "string" ? [role] : role;
}

async function loadSessionUser(): Promise<SessionUser | null> {
  const session = await auth();
  const userId = session?.user?.id;

  if (!userId) {
    return null;
  }

  // Re-read the user so a deleted account or a changed role takes effect immediately.
  const user = await db.user.findUnique({
    where: { id: userId },
    select: {
      id: true,
      role: true,
      name: true,
      email: true,
      studentProfile: { select: { id: true } },
      parentProfile: { select: { id: true } },
      teacherProfile: { select: { id: true } },
    },
  });

  if (!user) {
    return null;
  }

  const profileId = profileIdForRole(user.role, user);
  return { id: user.id, role: user.role, name: user.name, email: user.email, profileId };
}

/** Current user or null. Deduplicated per request. */
export const getSessionUser: () => Promise<SessionUser | null> = cache(loadSessionUser);

/** For pages and layouts: redirects to /dang-nhap when nobody is signed in. */
export async function requireUser(callbackPath?: string): Promise<SessionUser> {
  const user = await getSessionUser();

  if (!user) {
    redirect(buildSignInUrl(callbackPath ?? "/"));
  }
  return user;
}

/**
 * For pages and layouts: redirects anonymous visitors to /dang-nhap and answers a signed-in
 * user with the wrong role with `notFound()` (404): stable API, and it does not reveal that
 * the screen exists. Using `forbidden()` would need the experimental authInterrupts flag.
 */
export async function requireRole(role: Role | readonly Role[]): Promise<SessionUser> {
  const user = await requireUser();

  if (!toRoleList(role).includes(user.role)) {
    notFound();
  }
  return user;
}

/**
 * For Server Actions and route handlers: never redirects or throws, so the caller can
 * return a typed error to the client. Every action must start with this call.
 */
export async function requireRoleForAction(
  role: Role | readonly Role[],
): Promise<ActionAuthResult> {
  const user = await getSessionUser();

  if (!user) {
    return { ok: false, error: { code: "UNAUTHENTICATED", message: UNAUTHENTICATED_MESSAGE } };
  }
  if (!toRoleList(role).includes(user.role)) {
    return { ok: false, error: { code: "FORBIDDEN", message: FORBIDDEN_MESSAGE } };
  }
  return { ok: true, user };
}
