import { afterAll, afterEach, beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import type { ActionAuthResult, SessionUser } from "@/lib/auth/session";
import { db } from "@/lib/db";
import { createHocTapWorld, startExamAttempt, type HocTapWorld } from "@/test/hoc-tap-world";
import { CHAT_MAX_BODY_BYTES, CHAT_RATE_LIMIT } from "./constants";

const state = vi.hoisted(() => ({ user: null as unknown }));

vi.mock("@/lib/auth/session", () => ({
  requireRoleForAction: async (): Promise<ActionAuthResult> => {
    const user = state.user as SessionUser | null;
    if (!user) return { ok: false, error: { code: "UNAUTHENTICATED", message: "x" } };
    if (user.role !== "STUDENT") return { ok: false, error: { code: "FORBIDDEN", message: "x" } };
    return { ok: true, user };
  },
}));

vi.mock("@/lib/env", async (importActual) => {
  const actual = await importActual<typeof import("@/lib/env")>();
  return {
    ...actual,
    getEnv: () => ({
      ...actual.getEnv(),
      OPENCODE_API_KEY: "test-key-not-real",
      OPENCODE_BASE_URL: "https://ai.example.test/v1",
      AI_MODEL: "model-x",
    }),
  };
});

const { POST } = await import("@/app/api/ai/chat/route");

const ENDPOINT = "http://localhost:3000/api/ai/chat";
const fetchMock = vi.fn();
let world: HocTapWorld;

function post(body: BodyInit | null, headers: Record<string, string> = {}): Promise<Response> {
  return POST(
    new Request(ENDPOINT, {
      method: "POST",
      headers: { "content-type": "application/json", host: "localhost:3000", ...headers },
      body,
    }),
  );
}

const postMessage = (message: string, headers?: Record<string, string>) =>
  post(JSON.stringify({ message }), headers);

beforeAll(async () => {
  world = await createHocTapWorld();
});

afterAll(async () => {
  await world.cleanup();
  await db.$disconnect();
});

beforeEach(async () => {
  state.user = world.studentA;
  vi.stubGlobal("fetch", fetchMock);
  fetchMock.mockImplementation(
    async () => new Response(JSON.stringify({ choices: [{ message: { content: "Chào em" } }] })),
  );
  await db.rateLimitBucket.deleteMany({ where: { key: { contains: world.studentA.id } } });
});

afterEach(async () => {
  fetchMock.mockReset();
  vi.unstubAllGlobals();
  await db.examAttempt.deleteMany({ where: { assessmentId: world.examAssessmentId } });
});

describe("POST /api/ai/chat request guard", () => {
  it("answers 200 with the exchange for a same-origin JSON request", async () => {
    const response = await postMessage("Xin chào", { origin: "http://localhost:3000" });

    expect(response.status).toBe(200);
    expect(await response.json()).toMatchObject({
      ok: true,
      data: { messages: expect.any(Array) },
    });
  });

  it("rejects a cross-origin request with 403 before calling the model", async () => {
    const response = await postMessage("Xin chào", { origin: "https://evil.example" });

    expect(response.status).toBe(403);
    expect(await response.json()).toMatchObject({ ok: false, error: { code: "FORBIDDEN" } });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("rejects a non-JSON content type with 415", async () => {
    const response = await postMessage("Xin chào", { "content-type": "text/plain" });

    expect(response.status).toBe(415);
    expect(await response.json()).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
  });

  it("rejects a body over the limit with 413 even without a Content-Length", async () => {
    const oversized = JSON.stringify({ message: "a".repeat(CHAT_MAX_BODY_BYTES) });

    const response = await post(oversized);

    expect(response.status).toBe(413);
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("rejects an oversized declared Content-Length with 413 before reading the body", async () => {
    const response = await postMessage("Xin chào", {
      "content-length": String(CHAT_MAX_BODY_BYTES + 1),
    });

    expect(response.status).toBe(413);
  });

  it("rejects malformed JSON with 400", async () => {
    const response = await post("{not json");

    expect(response.status).toBe(400);
    expect(await response.json()).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
  });

  it("rejects an invalid message with 400", async () => {
    const response = await postMessage("   ");

    expect(response.status).toBe(400);
  });

  it("answers 401 for an anonymous caller and 403 for a non-student", async () => {
    state.user = null;
    expect((await postMessage("Xin chào")).status).toBe(401);

    state.user = world.parent;
    expect((await postMessage("Xin chào")).status).toBe(403);
    expect(fetchMock).not.toHaveBeenCalled();
  });
});

describe("POST /api/ai/chat limits", () => {
  it("answers 429 with the remaining window as Retry-After", async () => {
    const elapsedMs = 40_000;
    await db.rateLimitBucket.create({
      data: {
        key: `ai-chat:${world.studentA.id}`,
        count: CHAT_RATE_LIMIT,
        windowStart: new Date(Date.now() - elapsedMs),
      },
    });

    const response = await postMessage("Xin chào");

    expect(response.status).toBe(429);
    const retryAfter = Number(response.headers.get("retry-after"));
    expect(retryAfter).toBeGreaterThan(0);
    expect(retryAfter).toBeLessThanOrEqual(20);
    expect(await response.json()).not.toHaveProperty("retryAfterMs");
  });

  it("answers 403 with the Vietnamese lock message during an exam", async () => {
    await startExamAttempt(world, world.studentA.profileId);

    const response = await postMessage("Giải giúp câu 3");

    expect(response.status).toBe(403);
    expect(await response.json()).toMatchObject({
      error: { message: "Bạn đang làm bài thi, trợ lý AI tạm khóa." },
    });
  });
});
