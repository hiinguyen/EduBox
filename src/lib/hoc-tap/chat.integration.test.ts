import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { db } from "@/lib/db";
import { MS_PER_DAY, MS_PER_MINUTE } from "@/lib/format/time";
import { createHocTapWorld, startExamAttempt, type HocTapWorld } from "@/test/hoc-tap-world";
import {
  CHAT_DAILY_LIMIT,
  CHAT_GLOBAL_RATE_LIMIT,
  CHAT_HISTORY_VIEW_LIMIT,
  CHAT_RATE_LIMIT,
  CHAT_RATE_WINDOW_MS,
} from "./constants";

const envState = vi.hoisted(() => ({ ai: true }));

vi.mock("@/lib/env", async (importActual) => {
  const actual = await importActual<typeof import("@/lib/env")>();
  return {
    ...actual,
    getEnv: () => ({
      ...actual.getEnv(),
      OPENCODE_API_KEY: envState.ai ? "test-key-not-real" : undefined,
      OPENCODE_BASE_URL: envState.ai ? "https://ai.example.test/v1" : undefined,
      AI_MODEL: envState.ai ? "model-x" : undefined,
    }),
  };
});

const { sendTutorMessage, AI_NOT_CONFIGURED_MESSAGE } = await import("./chat-service");
const { loadChatHistory } = await import("./chat-history");
const { DAILY_LIMITED_MESSAGE, GLOBAL_CHAT_KEY, GLOBAL_LIMITED_MESSAGE, RATE_LIMITED_MESSAGE } =
  await import("./chat-limits");
const { EXAM_LOCK_MESSAGE } = await import("./exam-lock");

const fetchMock = vi.fn();
let world: HocTapWorld;

function replyWith(text: string): void {
  fetchMock.mockImplementation(
    async () => new Response(JSON.stringify({ choices: [{ message: { content: text } }] })),
  );
}

async function fillBucket(key: string, count: number, windowStart: Date): Promise<void> {
  await db.rateLimitBucket.upsert({
    where: { key },
    create: { key, count, windowStart },
    update: { count, windowStart },
  });
}

async function seedMessages(studentId: string, total: number): Promise<string> {
  const thread = await db.chatThread.create({ data: { studentId }, select: { id: true } });
  const base = Date.now() - total * MS_PER_MINUTE;
  await db.chatMessage.createMany({
    data: Array.from({ length: total }, (_, index) => ({
      threadId: thread.id,
      role: index % 2 === 0 ? ("STUDENT" as const) : ("ASSISTANT" as const),
      text: `tin nhắn ${index}`,
      createdAt: new Date(base + index * MS_PER_MINUTE),
    })),
  });
  return thread.id;
}

beforeAll(async () => {
  world = await createHocTapWorld();
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

beforeEach(async () => {
  envState.ai = true;
  vi.stubGlobal("fetch", fetchMock);
  replyWith("Em thử tính đạo hàm trước nhé?");
  const students = [world.studentA, world.studentB];
  await db.chatThread.deleteMany({
    where: { studentId: { in: students.map((student) => student.profileId) } },
  });
  await db.rateLimitBucket.deleteMany({
    where: {
      OR: [
        ...students.map((student) => ({ key: { contains: student.id } })),
        { key: GLOBAL_CHAT_KEY },
      ],
    },
  });
});

afterEach(async () => {
  fetchMock.mockReset();
  vi.unstubAllGlobals();
  await db.examAttempt.deleteMany({ where: { assessmentId: world.examAssessmentId } });
  await db.rateLimitBucket.deleteMany({ where: { key: GLOBAL_CHAT_KEY } });
});

describe("sendTutorMessage", () => {
  it("creates a thread and persists the student message and the reply", async () => {
    const result = await sendTutorMessage(world.studentA, { message: "  Cực trị là gì?  " });

    expect(result.ok).toBe(true);
    const history = await loadChatHistory(world.studentA.profileId);
    expect(history.messages.map((message) => [message.role, message.text])).toEqual([
      ["student", "Cực trị là gì?"],
      ["assistant", "Em thử tính đạo hàm trước nhé?"],
    ]);
  });

  it("sends the system prompt and the earlier turns of the thread to the model", async () => {
    const threadId = await seedMessages(world.studentA.profileId, 4);

    await sendTutorMessage(world.studentA, { message: "Tiếp theo?", threadId });

    const body = JSON.parse(String(fetchMock.mock.calls[0]?.[1]?.body));
    expect(body.messages[0].role).toBe("system");
    expect(body.messages.at(-1)).toEqual({ role: "user", content: "Tiếp theo?" });
    expect(body.messages.map((message: { content: string }) => message.content)).toEqual(
      expect.arrayContaining(["tin nhắn 0", "tin nhắn 3"]),
    );
  });

  it("persists nothing when the model call fails", async () => {
    fetchMock.mockResolvedValue(new Response("boom", { status: 500 }));

    const result = await sendTutorMessage(world.studentA, { message: "Xin chào" });

    expect(result).toMatchObject({ ok: false, error: { code: "INTERNAL" } });
    expect(
      await db.chatMessage.count({ where: { thread: { studentId: world.studentA.profileId } } }),
    ).toBe(0);
  });

  it("answers with the not configured message when the AI env is missing", async () => {
    envState.ai = false;

    const result = await sendTutorMessage(world.studentA, { message: "Xin chào" });

    expect(result).toEqual({
      ok: false,
      error: { code: "INTERNAL", message: AI_NOT_CONFIGURED_MESSAGE },
    });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("rejects an over-length or empty message", async () => {
    const long = await sendTutorMessage(world.studentA, { message: "a".repeat(501) });
    const empty = await sendTutorMessage(world.studentA, { message: "   " });

    expect(long).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
    expect(empty).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("does not let student B post into or read student A's thread", async () => {
    const threadId = await seedMessages(world.studentA.profileId, 2);

    const result = await sendTutorMessage(world.studentB, { message: "Xin chào", threadId });

    expect(result).toMatchObject({ ok: false, error: { code: "NOT_FOUND" } });
    const other = await loadChatHistory(world.studentB.profileId);
    expect(other).toEqual({ threadId: null, messages: [] });
  });

  it("keeps the history view bounded to the latest messages", async () => {
    await seedMessages(world.studentA.profileId, CHAT_HISTORY_VIEW_LIMIT + 5);

    const history = await loadChatHistory(world.studentA.profileId);

    expect(history.messages).toHaveLength(CHAT_HISTORY_VIEW_LIMIT);
    expect(history.messages.at(-1)?.text).toBe(`tin nhắn ${CHAT_HISTORY_VIEW_LIMIT + 4}`);
  });
});

describe("sendTutorMessage during an exam", () => {
  it("refuses while an attempt is in progress and calls nothing", async () => {
    await startExamAttempt(world, world.studentA.profileId);

    const result = await sendTutorMessage(world.studentA, { message: "Giải giúp câu 3" });

    expect(result).toEqual({
      ok: false,
      error: { code: "FORBIDDEN", message: EXAM_LOCK_MESSAGE },
    });
    expect(fetchMock).not.toHaveBeenCalled();
    expect(await db.chatThread.count({ where: { studentId: world.studentA.profileId } })).toBe(0);
  });

  it("allows the tutor again once the attempt time has run out", async () => {
    await startExamAttempt(world, world.studentA.profileId, new Date(Date.now() - 1_000));

    const result = await sendTutorMessage(world.studentA, { message: "Xin chào" });

    expect(result.ok).toBe(true);
  });

  it("does not lock a student because a classmate is taking an exam", async () => {
    await startExamAttempt(world, world.studentB.profileId);

    const result = await sendTutorMessage(world.studentA, { message: "Xin chào" });

    expect(result.ok).toBe(true);
  });
});

describe("sendTutorMessage limits", () => {
  it("blocks the message after the per-minute limit", async () => {
    for (let sent = 0; sent < CHAT_RATE_LIMIT; sent += 1) {
      const allowed = await sendTutorMessage(world.studentA, { message: `câu ${sent}` });
      expect(allowed.ok).toBe(true);
    }

    const blocked = await sendTutorMessage(world.studentA, { message: "câu cuối" });

    expect(blocked).toMatchObject({
      ok: false,
      error: { code: "RATE_LIMITED", message: RATE_LIMITED_MESSAGE },
    });
    expect(fetchMock).toHaveBeenCalledTimes(CHAT_RATE_LIMIT);
  });

  it("reports the real time left in the window, not the full window", async () => {
    const elapsedMs = 40_000;
    const key = `ai-chat:${world.studentA.id}`;
    await fillBucket(key, CHAT_RATE_LIMIT, new Date(Date.now() - elapsedMs));

    const blocked = await sendTutorMessage(world.studentA, { message: "Xin chào" });

    expect(blocked.ok).toBe(false);
    const retryAfterMs = blocked.ok ? 0 : (blocked.retryAfterMs ?? 0);
    expect(retryAfterMs).toBeGreaterThan(0);
    expect(retryAfterMs).toBeLessThanOrEqual(CHAT_RATE_WINDOW_MS - elapsedMs);
  });

  it("blocks the message after the daily limit with its own message", async () => {
    await fillBucket(`ai-chat-daily:${world.studentA.id}`, CHAT_DAILY_LIMIT, new Date());

    const blocked = await sendTutorMessage(world.studentA, { message: "Xin chào" });

    expect(blocked).toMatchObject({
      ok: false,
      error: { code: "RATE_LIMITED", message: DAILY_LIMITED_MESSAGE },
    });
    expect(blocked.ok ? 0 : blocked.retryAfterMs).toBeLessThanOrEqual(MS_PER_DAY);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("blocks every student once the global per-minute limit is reached", async () => {
    await fillBucket(GLOBAL_CHAT_KEY, CHAT_GLOBAL_RATE_LIMIT, new Date());

    const blocked = await sendTutorMessage(world.studentB, { message: "Xin chào" });

    expect(blocked).toMatchObject({
      ok: false,
      error: { code: "RATE_LIMITED", message: GLOBAL_LIMITED_MESSAGE },
    });
    expect(fetchMock).not.toHaveBeenCalled();
  });
});
