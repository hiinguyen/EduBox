import "server-only";
import type { ChatRole as DbChatRole } from "@/generated/prisma/enums";
import { chatThreadsOfStudent } from "@/lib/auth/access";
import { db } from "@/lib/db";
import { formatVnClock } from "@/lib/format/date";
import { CHAT_HISTORY_VIEW_LIMIT } from "./constants";
import type { ChatMessage, ChatRole } from "./types";

const ROLES: Readonly<Record<DbChatRole, ChatRole>> = {
  STUDENT: "student",
  ASSISTANT: "assistant",
};

interface ChatMessageRow {
  readonly id: string;
  readonly role: DbChatRole;
  readonly text: string;
  readonly quote: string | null;
  readonly highlight: string | null;
  readonly suggestions: readonly string[];
  readonly createdAt: Date;
}

export const chatMessageSelect = {
  id: true,
  role: true,
  text: true,
  quote: true,
  highlight: true,
  suggestions: true,
  createdAt: true,
} as const;

export function toChatMessage(row: ChatMessageRow): ChatMessage {
  return {
    id: row.id,
    role: ROLES[row.role],
    text: row.text,
    time: formatVnClock(row.createdAt),
    ...(row.quote ? { quote: row.quote } : {}),
    ...(row.highlight ? { highlight: row.highlight } : {}),
    ...(row.suggestions.length > 0 ? { suggestions: row.suggestions } : {}),
  };
}

export interface ChatHistory {
  readonly threadId: string | null;
  readonly messages: readonly ChatMessage[];
}

export async function loadChatHistory(studentId: string): Promise<ChatHistory> {
  const thread = await db.chatThread.findFirst({
    where: chatThreadsOfStudent(studentId),
    orderBy: { updatedAt: "desc" },
    select: {
      id: true,
      messages: {
        orderBy: { createdAt: "desc" },
        take: CHAT_HISTORY_VIEW_LIMIT,
        select: chatMessageSelect,
      },
    },
  });
  if (!thread) return { threadId: null, messages: [] };

  return { threadId: thread.id, messages: thread.messages.reverse().map(toChatMessage) };
}
