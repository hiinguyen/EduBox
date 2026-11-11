import "server-only";
import { chatThreadsOfStudent } from "@/lib/auth/access";
import type { SessionUser } from "@/lib/auth/session";
import { isAiConfigured, requestCompletion, type AiMessage } from "@/lib/ai/opencode-client";
import { TUTOR_SYSTEM_PROMPT } from "@/lib/ai/tutor-prompt";
import { db } from "@/lib/db";
import { DEFAULT_ERROR_MESSAGES, fail, failFromZod, ok } from "@/lib/server/action-result";
import type { ActionError } from "@/lib/server/action-result";
import { logServerError } from "@/lib/server/log";
import { chatMessageSelect, toChatMessage } from "./chat-history";
import { checkChatLimits } from "./chat-limits";
import { CHAT_CONTEXT_LIMIT } from "./constants";
import { EXAM_LOCK_MESSAGE, hasActiveExamAttempt } from "./exam-lock";
import { chatRequestSchema } from "./schemas";
import type { ChatMessage } from "./types";

export const AI_NOT_CONFIGURED_MESSAGE = "Trợ lý AI chưa được cấu hình.";
export const AI_UNAVAILABLE_MESSAGE = "Trợ lý AI đang bận. Vui lòng thử lại sau ít phút.";
export const THREAD_NOT_FOUND_MESSAGE = "Không tìm thấy cuộc trò chuyện.";
const THREAD_TITLE_LENGTH = 60;

/** A failed result that may also tell the caller how long to wait (for Retry-After). */
export interface ChatFailure {
  readonly ok: false;
  readonly error: ActionError;
  readonly retryAfterMs?: number;
}

export type ChatResult = { readonly ok: true; readonly data: ChatExchange } | ChatFailure;

export interface ChatExchange {
  readonly threadId: string;
  readonly messages: readonly ChatMessage[];
}

async function findThreadId(studentId: string, requested: string | undefined) {
  const thread = await db.chatThread.findFirst({
    where: { AND: [chatThreadsOfStudent(studentId), requested ? { id: requested } : {}] },
    orderBy: { updatedAt: "desc" },
    select: { id: true },
  });
  return thread?.id ?? null;
}

async function loadContext(threadId: string | null): Promise<readonly AiMessage[]> {
  if (!threadId) return [];
  const rows = await db.chatMessage.findMany({
    where: { threadId },
    orderBy: { createdAt: "desc" },
    take: CHAT_CONTEXT_LIMIT,
    select: { role: true, text: true },
  });
  return rows.reverse().map((row) => ({
    role: row.role === "STUDENT" ? "user" : "assistant",
    content: row.text,
  }));
}

interface PersistInput {
  readonly user: SessionUser;
  readonly threadId: string | null;
  readonly studentText: string;
  readonly assistantText: string;
  readonly askedAt: Date;
}

async function persistExchange(input: PersistInput): Promise<ChatExchange> {
  const { user, studentText, assistantText, askedAt } = input;
  return db.$transaction(async (tx) => {
    const threadId =
      input.threadId ??
      (
        await tx.chatThread.create({
          data: { studentId: user.profileId, title: studentText.slice(0, THREAD_TITLE_LENGTH) },
          select: { id: true },
        })
      ).id;
    const student = await tx.chatMessage.create({
      data: { threadId, role: "STUDENT", text: studentText, createdAt: askedAt },
      select: chatMessageSelect,
    });
    const assistant = await tx.chatMessage.create({
      data: { threadId, role: "ASSISTANT", text: assistantText, createdAt: new Date() },
      select: chatMessageSelect,
    });
    await tx.chatThread.update({ where: { id: threadId }, data: { updatedAt: new Date() } });
    return { threadId, messages: [toChatMessage(student), toChatMessage(assistant)] };
  });
}

async function reject(user: SessionUser, now: Date): Promise<ChatFailure | null> {
  if (!isAiConfigured()) return fail("INTERNAL", AI_NOT_CONFIGURED_MESSAGE);
  if (await hasActiveExamAttempt(user.profileId, now)) return fail("FORBIDDEN", EXAM_LOCK_MESSAGE);

  const verdict = await checkChatLimits(user.id);
  if (verdict.isAllowed) return null;
  return { ...fail("RATE_LIMITED", verdict.message), retryAfterMs: verdict.retryAfterMs };
}

export async function sendTutorMessage(user: SessionUser, input: unknown): Promise<ChatResult> {
  const parsed = chatRequestSchema.safeParse(input);
  if (!parsed.success) return failFromZod(parsed.error);
  const { message, threadId: requested } = parsed.data;

  const askedAt = new Date();
  try {
    const rejection = await reject(user, askedAt);
    if (rejection) return rejection;

    const threadId = await findThreadId(user.profileId, requested);
    if (requested && !threadId) return fail("NOT_FOUND", THREAD_NOT_FOUND_MESSAGE);

    const history = await loadContext(threadId);
    const reply = await requestCompletion([
      { role: "system", content: TUTOR_SYSTEM_PROMPT },
      ...history,
      { role: "user", content: message },
    ]);
    if (!reply.ok) {
      logServerError(`ai-${reply.detail}`, null, { userId: user.id });
      return fail("INTERNAL", AI_UNAVAILABLE_MESSAGE);
    }
    const exchange = await persistExchange({
      user,
      threadId,
      studentText: message,
      assistantText: reply.text,
      askedAt,
    });
    return ok(exchange);
  } catch (error) {
    logServerError("chat", error, { userId: user.id });
    return fail("INTERNAL", DEFAULT_ERROR_MESSAGES.INTERNAL);
  }
}
