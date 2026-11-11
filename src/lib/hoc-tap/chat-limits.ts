import "server-only";
import { rateLimit } from "@/lib/rate-limit";
import {
  CHAT_DAILY_LIMIT,
  CHAT_DAILY_WINDOW_MS,
  CHAT_GLOBAL_RATE_LIMIT,
  CHAT_GLOBAL_WINDOW_MS,
  CHAT_RATE_LIMIT,
  CHAT_RATE_WINDOW_MS,
} from "./constants";

export const RATE_LIMITED_MESSAGE = "Bạn gửi tin nhắn quá nhanh. Vui lòng thử lại sau ít phút.";
export const DAILY_LIMITED_MESSAGE =
  "Bạn đã dùng hết lượt hỏi trợ lý AI hôm nay. Vui lòng quay lại vào ngày mai.";
export const GLOBAL_LIMITED_MESSAGE =
  "Trợ lý AI đang có quá nhiều người dùng. Vui lòng thử lại sau ít phút.";

export const GLOBAL_CHAT_KEY = "ai-chat-global";

interface LimitTier {
  readonly key: (userId: string) => string;
  readonly limit: number;
  readonly windowMs: number;
  readonly message: string;
}

/** Checked in order; the cheapest per-user guard first so a flood cannot burn the shared budget. */
const TIERS: readonly LimitTier[] = [
  {
    key: (userId) => `ai-chat:${userId}`,
    limit: CHAT_RATE_LIMIT,
    windowMs: CHAT_RATE_WINDOW_MS,
    message: RATE_LIMITED_MESSAGE,
  },
  {
    key: (userId) => `ai-chat-daily:${userId}`,
    limit: CHAT_DAILY_LIMIT,
    windowMs: CHAT_DAILY_WINDOW_MS,
    message: DAILY_LIMITED_MESSAGE,
  },
  {
    key: () => GLOBAL_CHAT_KEY,
    limit: CHAT_GLOBAL_RATE_LIMIT,
    windowMs: CHAT_GLOBAL_WINDOW_MS,
    message: GLOBAL_LIMITED_MESSAGE,
  },
];

export type ChatLimitVerdict =
  | { readonly isAllowed: true }
  | { readonly isAllowed: false; readonly retryAfterMs: number; readonly message: string };

export async function checkChatLimits(userId: string): Promise<ChatLimitVerdict> {
  for (const tier of TIERS) {
    const result = await rateLimit(tier.key(userId), {
      limit: tier.limit,
      windowMs: tier.windowMs,
    });
    if (!result.isAllowed) {
      return { isAllowed: false, retryAfterMs: result.retryAfterMs, message: tier.message };
    }
  }
  return { isAllowed: true };
}
