import { z } from "zod";
import { formatRelativeDayLabel } from "@/lib/format/date";
import type { ActivityKind } from "@/generated/prisma/enums";
import { TONES } from "@/lib/ui/tone";
import type { ActivityEntry, ActivityTone } from "./types";

const descriptionSchema = z.array(
  z.object({ text: z.string().min(1), isEmphasis: z.boolean().optional() }),
);
const tagsSchema = z.array(z.object({ label: z.string().min(1), tone: z.enum(TONES) }));

const KIND_STYLE: Readonly<Record<ActivityKind, { icon: string; tone: ActivityTone }>> = {
  EXAM_COMPLETED: { icon: "assignment_turned_in", tone: "primary" },
  LECTURE_WATCHED: { icon: "play_circle", tone: "secondary" },
  AI_TUTOR: { icon: "psychology", tone: "neutral" },
  HOMEWORK_SUBMITTED: { icon: "task_alt", tone: "primary" },
};

export interface ActivityRow {
  readonly id: string;
  readonly kind: ActivityKind;
  readonly title: string;
  readonly description: unknown;
  readonly tags: unknown;
  readonly occurredAt: Date;
}

/**
 * Validates the JSON columns and shapes one row for display.
 * Returns null for a row whose JSON does not match, so one bad row cannot break the page.
 */
export function toActivityEntry(row: ActivityRow, now: Date): ActivityEntry | null {
  const description = descriptionSchema.safeParse(row.description);
  const tags = tagsSchema.safeParse(row.tags);
  if (!description.success || !tags.success) return null;

  const style = KIND_STYLE[row.kind];
  return {
    id: row.id,
    icon: style.icon,
    tone: style.tone,
    title: row.title,
    timeLabel: formatRelativeDayLabel(row.occurredAt, now),
    description: description.data,
    tags: tags.data,
  };
}
