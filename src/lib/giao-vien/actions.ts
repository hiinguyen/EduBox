"use server";

import { revalidatePath } from "next/cache";
import { requireRoleForAction } from "@/lib/auth/session";
import { rateLimit } from "@/lib/rate-limit";
import { fail, failFromAuth } from "@/lib/server/action-result";
import { logServerError } from "@/lib/server/log";
import {
  GRADE_RATE_KEY_PREFIX,
  GRADE_RATE_LIMIT,
  GRADE_RATE_WINDOW_MS,
  PARENT_PORTAL_PATH,
  WORKSPACE_PATH,
} from "./constants";
import { saveGrade, type SaveGradeResult } from "./save-grade";

export async function saveGradeAction(input: unknown): Promise<SaveGradeResult> {
  const auth = await requireRoleForAction("TEACHER");
  if (!auth.ok) return failFromAuth(auth.error);

  try {
    const limit = await rateLimit(`${GRADE_RATE_KEY_PREFIX}:${auth.user.id}`, {
      limit: GRADE_RATE_LIMIT,
      windowMs: GRADE_RATE_WINDOW_MS,
    });
    if (!limit.isAllowed) return fail("RATE_LIMITED");

    const result = await saveGrade(auth.user, input);
    if (result.ok) {
      revalidatePath(WORKSPACE_PATH);
      revalidatePath(PARENT_PORTAL_PATH);
    }
    return result;
  } catch (error) {
    logServerError("giao-vien.saveGradeAction", error, { userId: auth.user.id });
    return fail("INTERNAL");
  }
}
