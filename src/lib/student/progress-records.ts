import "server-only";
import type { Prisma } from "@/generated/prisma/client";
import type { ActivityKind, Subject } from "@/generated/prisma/enums";
import { getVnCalendarDay, startOfVnWeek } from "@/lib/format/date";
import { roundTo } from "@/lib/format/number";
import type { Tone } from "@/lib/ui/tone";

type Tx = Prisma.TransactionClient;

export interface ActivityDescriptionSegment {
  readonly text: string;
  readonly isEmphasis?: boolean;
}

export interface ActivityTag {
  readonly label: string;
  readonly tone: Tone;
}

const MIN_SCORE = 0;
const MAX_SCORE = 10;
const SCORE_DECIMALS = 1;

/** Date columns hold a calendar day, so they are stored as UTC midnight of the VN day. */
function toDateColumn(date: Date): Date {
  return new Date(`${getVnCalendarDay(date)}T00:00:00.000Z`);
}

export async function recordStudyTime(
  tx: Tx,
  input: { studentId: string; at: Date; seconds: number },
): Promise<void> {
  const seconds = Math.floor(input.seconds);
  if (!(seconds > 0)) return;
  const { studentId } = input;
  const day = toDateColumn(input.at);
  await tx.studyDay.upsert({
    where: { studentId_day: { studentId, day } },
    create: { studentId, day, studiedSeconds: seconds },
    update: { studiedSeconds: { increment: seconds } },
  });
}

export async function recordActivity(
  tx: Tx,
  input: {
    studentId: string;
    kind: ActivityKind;
    title: string;
    description: ActivityDescriptionSegment[];
    tags: ActivityTag[];
    occurredAt: Date;
  },
): Promise<void> {
  const { studentId, kind, title, occurredAt } = input;
  await tx.activityLog.create({
    data: {
      studentId,
      kind,
      title,
      occurredAt,
      // Plain literals so the JSON columns get exactly the shapes the parent portal validates.
      description: input.description.map(({ text, isEmphasis }) =>
        isEmphasis === undefined ? { text } : { text, isEmphasis },
      ),
      tags: input.tags.map(({ label, tone }) => ({ label, tone })),
    },
  });
}

/** The latest graded score of the week wins; the value is clamped to 0..10 and kept to one decimal. */
export async function recordSubjectScore(
  tx: Tx,
  input: { studentId: string; subject: Subject; at: Date; scoreOutOf10: number },
): Promise<void> {
  const { studentId, subject } = input;
  if (!Number.isFinite(input.scoreOutOf10)) return;
  const weekStart = toDateColumn(startOfVnWeek(input.at));
  const score = roundTo(
    Math.min(MAX_SCORE, Math.max(MIN_SCORE, input.scoreOutOf10)),
    SCORE_DECIMALS,
  );
  await tx.subjectWeekScore.upsert({
    where: { studentId_subject_weekStart: { studentId, subject, weekStart } },
    create: { studentId, subject, weekStart, score },
    update: { score },
  });
}
