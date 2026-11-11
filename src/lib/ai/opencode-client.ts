import "server-only";
import { z } from "zod";
import { getEnv } from "@/lib/env";
import {
  AI_REQUEST_TIMEOUT_MS,
  CHAT_COMPLETIONS_PATH,
  MAX_AI_REPLY_LENGTH,
  MAX_COMPLETION_TOKENS,
  TUTOR_TEMPERATURE,
} from "./constants";

export type AiMessageRole = "system" | "user" | "assistant";

export interface AiMessage {
  readonly role: AiMessageRole;
  readonly content: string;
}

export type AiFailureReason = "NOT_CONFIGURED" | "UNAVAILABLE";

export type AiResult =
  | { readonly ok: true; readonly text: string }
  | { readonly ok: false; readonly reason: AiFailureReason; readonly detail: string };

const completionSchema = z.object({
  choices: z.array(z.object({ message: z.object({ content: z.string().trim().min(1) }) })).min(1),
});

interface AiConfig {
  readonly apiKey: string;
  readonly endpoint: string;
  readonly model: string;
}

function readConfig(): AiConfig | null {
  const { OPENCODE_API_KEY, OPENCODE_BASE_URL, AI_MODEL } = getEnv();
  if (!OPENCODE_API_KEY || !OPENCODE_BASE_URL || !AI_MODEL) return null;

  const base = OPENCODE_BASE_URL.replace(/\/+$/, "");
  const endpoint = base.endsWith(CHAT_COMPLETIONS_PATH) ? base : `${base}${CHAT_COMPLETIONS_PATH}`;
  return { apiKey: OPENCODE_API_KEY, endpoint, model: AI_MODEL };
}

export function isAiConfigured(): boolean {
  return readConfig() !== null;
}

function unavailable(detail: string): AiResult {
  return { ok: false, reason: "UNAVAILABLE", detail };
}

async function post(config: AiConfig, messages: readonly AiMessage[]): Promise<Response> {
  return fetch(config.endpoint, {
    method: "POST",
    headers: { "Content-Type": "application/json", Authorization: `Bearer ${config.apiKey}` },
    body: JSON.stringify({
      model: config.model,
      messages,
      temperature: TUTOR_TEMPERATURE,
      max_tokens: MAX_COMPLETION_TOKENS,
      stream: false,
    }),
    signal: AbortSignal.timeout(AI_REQUEST_TIMEOUT_MS),
    cache: "no-store",
  });
}

/** Calls the OpenAI-compatible endpoint. `detail` is safe to log: status or error class only. */
export async function requestCompletion(messages: readonly AiMessage[]): Promise<AiResult> {
  const config = readConfig();
  if (!config) return { ok: false, reason: "NOT_CONFIGURED", detail: "missing-config" };

  let response: Response;
  try {
    response = await post(config, messages);
  } catch (error) {
    return unavailable(error instanceof Error ? error.name : "fetch-failed");
  }
  if (!response.ok) return unavailable(`status-${response.status}`);

  let payload: unknown;
  try {
    payload = await response.json();
  } catch {
    return unavailable("invalid-json");
  }
  const parsed = completionSchema.safeParse(payload);
  if (!parsed.success) return unavailable("invalid-shape");

  const content = parsed.data.choices[0]?.message.content ?? "";
  return { ok: true, text: content.slice(0, MAX_AI_REPLY_LENGTH) };
}
