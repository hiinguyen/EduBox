import { describe, expect, it } from "vitest";
import { assertSameOriginJson, readJsonBody } from "./request-guard";

const MAX = 100;

function post(headers: Record<string, string>, body: BodyInit | null = "{}"): Request {
  return new Request("https://edubox.test/api/ai/chat", { method: "POST", headers, body });
}

const sameOriginJson = {
  origin: "https://edubox.test",
  host: "edubox.test",
  "content-type": "application/json; charset=utf-8",
};

function withoutOrigin(): Record<string, string> {
  return Object.fromEntries(Object.entries(sameOriginJson).filter(([name]) => name !== "origin"));
}

describe("assertSameOriginJson", () => {
  it("accepts a same-origin JSON request within the size limit", () => {
    expect(assertSameOriginJson(post(sameOriginJson), { maxBytes: MAX })).toEqual({ ok: true });
  });

  it("rejects a request from another origin", () => {
    const result = assertSameOriginJson(post({ ...sameOriginJson, origin: "https://evil.test" }), {
      maxBytes: MAX,
    });

    expect(result).toMatchObject({ ok: false, reason: "CROSS_ORIGIN", status: 403 });
  });

  it("rejects a malformed Origin header", () => {
    const result = assertSameOriginJson(post({ ...sameOriginJson, origin: "null" }), {
      maxBytes: MAX,
    });

    expect(result).toMatchObject({ ok: false, reason: "CROSS_ORIGIN" });
  });

  it("rejects a missing Origin when Fetch Metadata says cross-site", () => {
    const rest = withoutOrigin();
    const result = assertSameOriginJson(post({ ...rest, "sec-fetch-site": "cross-site" }), {
      maxBytes: MAX,
    });

    expect(result).toMatchObject({ ok: false, reason: "CROSS_ORIGIN" });
  });

  it("allows a missing Origin for non-browser clients", () => {
    const rest = withoutOrigin();

    expect(assertSameOriginJson(post(rest), { maxBytes: MAX })).toEqual({ ok: true });
  });

  it("requires application/json", () => {
    const result = assertSameOriginJson(post({ ...sameOriginJson, "content-type": "text/plain" }), {
      maxBytes: MAX,
    });

    expect(result).toMatchObject({ ok: false, reason: "UNSUPPORTED_MEDIA_TYPE", status: 415 });
  });

  it("rejects a Content-Length above the limit before reading the body", () => {
    const result = assertSameOriginJson(post({ ...sameOriginJson, "content-length": "101" }), {
      maxBytes: MAX,
    });

    expect(result).toMatchObject({ ok: false, reason: "PAYLOAD_TOO_LARGE", status: 413 });
  });

  it("rejects a malformed Content-Length", () => {
    const result = assertSameOriginJson(post({ ...sameOriginJson, "content-length": "abc" }), {
      maxBytes: MAX,
    });

    expect(result).toMatchObject({ ok: false, reason: "PAYLOAD_TOO_LARGE" });
  });
});

describe("readJsonBody", () => {
  it("parses a JSON body", async () => {
    const result = await readJsonBody(post(sameOriginJson, '{"a":1}'), MAX);

    expect(result).toEqual({ ok: true, data: { a: 1 } });
  });

  it("rejects a declared length above the limit without reading", async () => {
    const result = await readJsonBody(post({ ...sameOriginJson, "content-length": "500" }), MAX);

    expect(result).toMatchObject({ ok: false, reason: "PAYLOAD_TOO_LARGE" });
  });

  it("stops reading a chunked body once it exceeds the limit", async () => {
    let pulls = 0;
    const stream = new ReadableStream<Uint8Array>({
      pull(controller) {
        pulls += 1;
        controller.enqueue(new TextEncoder().encode("x".repeat(40)));
      },
    });
    const request = new Request("https://edubox.test/api", {
      method: "POST",
      headers: sameOriginJson,
      body: stream,
      duplex: "half",
    } as RequestInit);

    const result = await readJsonBody(request, MAX);

    expect(result).toMatchObject({ ok: false, reason: "PAYLOAD_TOO_LARGE" });
    expect(pulls).toBeLessThan(10);
  });

  it("reports invalid JSON", async () => {
    const result = await readJsonBody(post(sameOriginJson, "{nope"), MAX);

    expect(result).toMatchObject({ ok: false, reason: "INVALID_JSON", status: 400 });
  });

  it("reports an empty body as invalid JSON", async () => {
    const result = await readJsonBody(post(sameOriginJson, null), MAX);

    expect(result).toMatchObject({ ok: false, reason: "INVALID_JSON" });
  });
});
