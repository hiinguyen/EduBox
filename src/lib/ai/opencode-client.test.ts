import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { MAX_AI_REPLY_LENGTH } from "./constants";
import { requestCompletion } from "./opencode-client";

const envState = vi.hoisted(() => ({
  value: {} as Record<string, string | undefined>,
}));

vi.mock("@/lib/env", () => ({ getEnv: () => envState.value }));

const CONFIGURED = {
  OPENCODE_API_KEY: "test-key-not-real",
  OPENCODE_BASE_URL: "https://ai.example.test/v1/",
  AI_MODEL: "model-x",
};
const messages = [{ role: "user", content: "xin chào" }] as const;

function jsonResponse(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), { status });
}

const fetchMock = vi.fn();

beforeEach(() => {
  envState.value = { ...CONFIGURED };
  vi.stubGlobal("fetch", fetchMock);
});

afterEach(() => {
  fetchMock.mockReset();
  vi.unstubAllGlobals();
});

describe("requestCompletion", () => {
  it("reports not configured without calling the network", async () => {
    envState.value = {};

    const result = await requestCompletion(messages);

    expect(result).toMatchObject({ ok: false, reason: "NOT_CONFIGURED" });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("posts to the chat completions endpoint with the bearer key and model", async () => {
    fetchMock.mockResolvedValue(jsonResponse({ choices: [{ message: { content: "Chào em" } }] }));

    const result = await requestCompletion(messages);

    const [url, init] = fetchMock.mock.calls[0] as [string, RequestInit];
    expect(url).toBe("https://ai.example.test/v1/chat/completions");
    expect((init.headers as Record<string, string>).Authorization).toBe("Bearer test-key-not-real");
    expect(JSON.parse(String(init.body)).model).toBe("model-x");
    expect(result).toEqual({ ok: true, text: "Chào em" });
  });

  it("truncates an over-long reply", async () => {
    const long = "a".repeat(MAX_AI_REPLY_LENGTH + 50);
    fetchMock.mockResolvedValue(jsonResponse({ choices: [{ message: { content: long } }] }));

    const result = await requestCompletion(messages);

    expect(result.ok && result.text.length).toBe(MAX_AI_REPLY_LENGTH);
  });

  it("fails on a non-200 status without leaking the body", async () => {
    fetchMock.mockResolvedValue(jsonResponse({ error: "secret detail" }, 500));

    const result = await requestCompletion(messages);

    expect(result).toEqual({ ok: false, reason: "UNAVAILABLE", detail: "status-500" });
  });

  it("fails on an empty reply", async () => {
    fetchMock.mockResolvedValue(jsonResponse({ choices: [{ message: { content: "  " } }] }));

    expect(await requestCompletion(messages)).toMatchObject({ ok: false, detail: "invalid-shape" });
  });

  it("fails on invalid JSON", async () => {
    fetchMock.mockResolvedValue(new Response("<html>", { status: 200 }));

    expect(await requestCompletion(messages)).toMatchObject({ ok: false, detail: "invalid-json" });
  });

  it("fails when the request times out", async () => {
    fetchMock.mockRejectedValue(new DOMException("timeout", "TimeoutError"));

    expect(await requestCompletion(messages)).toMatchObject({
      ok: false,
      reason: "UNAVAILABLE",
      detail: "TimeoutError",
    });
  });
});
