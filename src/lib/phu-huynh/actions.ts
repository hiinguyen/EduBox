"use server";

import { revalidatePath } from "next/cache";
import { canParentViewChild, contactBookOfParent } from "@/lib/auth/access";
import { requireRoleForAction, type SessionUser } from "@/lib/auth/session";
import { db } from "@/lib/db";
import { fail, failFromAuth, failFromZod, ok, type ActionResult } from "@/lib/server/action-result";
import { logServerError } from "@/lib/server/log";
import { rateLimit } from "@/lib/rate-limit";
import { NOTE_ACK_RATE_KEY_PREFIX, SETTING_RATE_KEY_PREFIX, WRITE_RATE_LIMIT } from "./constants";
import { acknowledgeNoteSchema, setCompanionSettingSchema } from "./schema";
import type { SetCompanionSettingInput } from "./schema";

const DASHBOARD_PATH = "/phu-huynh";

async function isRateLimited(prefix: string, user: SessionUser): Promise<boolean> {
  const result = await rateLimit(`${prefix}:${user.id}`, WRITE_RATE_LIMIT);
  return !result.isAllowed;
}

function toSettingData(input: SetCompanionSettingInput) {
  return input.settingId === "night-limit"
    ? { isNightLimitOn: input.isEnabled }
    : { isInstantAlertOn: input.isEnabled };
}

/** Persists one companion switch for one of the signed-in parent's children. */
export async function setCompanionSettingAction(input: unknown): Promise<ActionResult<null>> {
  const auth = await requireRoleForAction("PARENT");
  if (!auth.ok) return failFromAuth(auth.error);

  const parsed = setCompanionSettingSchema.safeParse(input);
  if (!parsed.success) return failFromZod(parsed.error);

  const parentId = auth.user.profileId;
  const { childId } = parsed.data;
  try {
    if (await isRateLimited(SETTING_RATE_KEY_PREFIX, auth.user)) return fail("RATE_LIMITED");
    if (!(await canParentViewChild(parentId, childId))) return fail("NOT_FOUND");
    const data = toSettingData(parsed.data);
    await db.parentSettings.upsert({
      where: { parentId_studentId: { parentId, studentId: childId } },
      update: data,
      create: { parentId, studentId: childId, ...data },
    });
  } catch (error: unknown) {
    logServerError("phu-huynh.set-setting", error, { parentId, childId });
    return fail("INTERNAL");
  }
  revalidatePath(DASHBOARD_PATH);
  return ok(null);
}

/** Confirms a contact book entry about one of the signed-in parent's children as read. */
export async function acknowledgeNoteAction(input: unknown): Promise<ActionResult<null>> {
  const auth = await requireRoleForAction("PARENT");
  if (!auth.ok) return failFromAuth(auth.error);

  const parsed = acknowledgeNoteSchema.safeParse(input);
  if (!parsed.success) return failFromZod(parsed.error);

  const parentId = auth.user.profileId;
  const { noteId } = parsed.data;
  const ownNote = { AND: [contactBookOfParent(parentId), { id: noteId }] };
  try {
    if (await isRateLimited(NOTE_ACK_RATE_KEY_PREFIX, auth.user)) return fail("RATE_LIMITED");
    const now = new Date();
    const updated = await db.parentTeacherNote.updateMany({
      where: { AND: [ownNote, { acknowledgedAt: null }] },
      data: { readAt: now, acknowledgedAt: now, acknowledgedById: parentId },
    });
    // Zero rows means the note is either already acknowledged (fine) or not this parent's.
    if (updated.count === 0 && (await db.parentTeacherNote.count({ where: ownNote })) === 0) {
      return fail("NOT_FOUND");
    }
  } catch (error: unknown) {
    logServerError("phu-huynh.acknowledge-note", error, { parentId, noteId });
    return fail("INTERNAL");
  }
  revalidatePath(DASHBOARD_PATH);
  return ok(null);
}
