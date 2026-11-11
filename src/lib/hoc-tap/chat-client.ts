import { z } from "zod";
import { DEFAULT_ERROR_MESSAGES, fail } from "@/lib/server/action-result";
import type { ActionErrorCode, ActionResult } from "@/lib/server/action-result";
import { chatRequestSchema } from "./schemas";
import type { ChatMessage } from "./types";

export const CHAT_ENDPOINT = "/api/ai/chat";
export const NETWORK_ERROR_MESSAGE = "Không thể kết nối. Vui lòng kiểm tra mạng và thử lại.";

const messageSchema = z.object({
  id: z.string(),
  role: z.enum(["student", "assistant"]),
  text: z.string(),
  time: z.string(),
  quote: z.string().optional(),
  highlight: z.string().optional(),
  suggestions: z.array(z.string()).optional(),
});

/** A Record keyed by the shared type fails to compile when a new code is not listed here. */
const KNOWN_ERROR_CODES: Readonly<Record<ActionErrorCode, true>> = {
  UNAUTHENTICATED: true,
  FORBIDDEN: true,
  INVALID_INPUT: true,
  NOT_FOUND: true,
  RATE_LIMITED: true,
  CONFLICT: true,
  INTERNAL: true,
};

const errorCodeSchema = z
  .string()
  .refine((code): code is ActionErrorCode => Object.hasOwn(KNOWN_ERROR_CODES, code));

const responseSchema = z.discriminatedUnion("ok", [
  z.object({
    ok: z.literal(true),
    data: z.object({ threadId: z.string(), messages: z.array(messageSchema) }),
  }),
  z.object({
    ok: z.literal(false),
    error: z.object({ code: errorCodeSchema, message: z.string() }),
  }),
]);

export interface ChatReply {
  readonly threadId: string;
  readonly messages: readonly ChatMessage[];
}

export async function postChatMessage(
  message: string,
  threadId: string | null,
): Promise<ActionResult<ChatReply>> {
  const body = chatRequestSchema.safeParse({ message, ...(threadId ? { threadId } : {}) });
  if (!body.success) return fail("INVALID_INPUT", DEFAULT_ERROR_MESSAGES.INVALID_INPUT);

  try {
    const response = await fetch(CHAT_ENDPOINT, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body.data),
    });
    const parsed = responseSchema.safeParse(await response.json());
    return parsed.success ? parsed.data : fail("INTERNAL", NETWORK_ERROR_MESSAGE);
  } catch {
    return fail("INTERNAL", NETWORK_ERROR_MESSAGE);
  }
}
