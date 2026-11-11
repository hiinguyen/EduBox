import { afterEach, describe, expect, it, vi } from "vitest";
import { NETWORK_ERROR_MESSAGE, postChatMessage } from "./chat-client";

const fetchMock = vi.fn();

afterEach(() => {
  fetchMock.mockReset();
  vi.unstubAllGlobals();
});

function stubFetch(response: unknown): void {
  fetchMock.mockResolvedValue(new Response(JSON.stringify(response)));
  vi.stubGlobal("fetch", fetchMock);
}

describe("postChatMessage", () => {
  it("returns the exchange from a successful response", async () => {
    const message = { id: "m1", role: "assistant", text: "Chào", time: "09:00" };
    stubFetch({ ok: true, data: { threadId: "t1", messages: [message] } });

    const result = await postChatMessage("xin chào", null);

    expect(result).toEqual({ ok: true, data: { threadId: "t1", messages: [message] } });
    expect(JSON.parse(String(fetchMock.mock.calls[0]?.[1]?.body))).toEqual({ message: "xin chào" });
  });

  it("passes through a typed server error", async () => {
    stubFetch({
      ok: false,
      error: { code: "RATE_LIMITED", message: "Bạn gửi tin nhắn quá nhanh." },
    });

    const result = await postChatMessage("a", "t1");

    expect(result).toEqual({
      ok: false,
      error: { code: "RATE_LIMITED", message: "Bạn gửi tin nhắn quá nhanh." },
    });
  });

  it("returns INVALID_INPUT without calling the server for an invalid message", async () => {
    vi.stubGlobal("fetch", fetchMock);

    const result = await postChatMessage("   ", null);

    expect(result).toMatchObject({ ok: false, error: { code: "INVALID_INPUT" } });
    expect(fetchMock).not.toHaveBeenCalled();
  });

  it("treats an unknown error code as a malformed response", async () => {
    stubFetch({ ok: false, error: { code: "AI_UNAVAILABLE", message: "x" } });

    const result = await postChatMessage("a", null);

    expect(result).toMatchObject({ ok: false, error: { message: NETWORK_ERROR_MESSAGE } });
  });

  it("falls back to a friendly message on a malformed response", async () => {
    stubFetch({ unexpected: true });

    const result = await postChatMessage("a", null);

    expect(result).toMatchObject({ ok: false, error: { message: NETWORK_ERROR_MESSAGE } });
  });

  it("falls back to a friendly message when the network fails", async () => {
    fetchMock.mockRejectedValue(new TypeError("offline"));
    vi.stubGlobal("fetch", fetchMock);

    const result = await postChatMessage("a", null);

    expect(result).toMatchObject({ ok: false, error: { message: NETWORK_ERROR_MESSAGE } });
  });
});
