import { z } from "zod";

const ID_PATTERN = /^[a-z0-9-]{1,64}$/;

const idSchema = z.string().regex(ID_PATTERN);

export const dashboardSearchParamsSchema = z.object({
  con: idSchema.optional(),
});

export type DashboardSearchParams = z.infer<typeof dashboardSearchParamsSchema>;

export const SETTING_IDS = ["night-limit", "instant-alerts"] as const;
export type SettingId = (typeof SETTING_IDS)[number];

export const setCompanionSettingSchema = z.object({
  childId: idSchema,
  settingId: z.enum(SETTING_IDS),
  isEnabled: z.boolean(),
});

export type SetCompanionSettingInput = z.infer<typeof setCompanionSettingSchema>;

export const acknowledgeNoteSchema = z.object({
  noteId: idSchema,
});

export type AcknowledgeNoteInput = z.infer<typeof acknowledgeNoteSchema>;
