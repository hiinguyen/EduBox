import { describe, expect, it } from "vitest";
import { z } from "zod";
import { DEFAULT_ERROR_MESSAGES, fail, failFromAuth, failFromZod, ok } from "./action-result";

describe("action results", () => {
  it("wraps data in an ok result", () => {
    expect(ok({ id: "1" })).toEqual({ ok: true, data: { id: "1" } });
  });

  it("uses the Vietnamese default message for a code", () => {
    expect(fail("NOT_FOUND")).toEqual({
      ok: false,
      error: { code: "NOT_FOUND", message: DEFAULT_ERROR_MESSAGES.NOT_FOUND },
    });
  });

  it("keeps a custom message", () => {
    expect(fail("CONFLICT", "Đã nộp bài").error.message).toBe("Đã nộp bài");
  });

  it("maps auth errors keeping the code", () => {
    const result = failFromAuth({ code: "FORBIDDEN", message: "x" });

    expect(result.error).toEqual({ code: "FORBIDDEN", message: "x" });
  });

  it("maps Zod errors to a Vietnamese INVALID_INPUT without leaking input", () => {
    const parsed = z.object({ name: z.string() }).safeParse({ name: 5, secret: "hunter2" });
    if (parsed.success) throw new Error("expected failure");

    const result = failFromZod(parsed.error);

    expect(result.error.code).toBe("INVALID_INPUT");
    expect(result.error.message).toBe(`${DEFAULT_ERROR_MESSAGES.INVALID_INPUT} (trường: name)`);
    expect(JSON.stringify(result)).not.toContain("hunter2");
  });

  it("defines a message for every code", () => {
    for (const message of Object.values(DEFAULT_ERROR_MESSAGES)) {
      expect(message.length).toBeGreaterThan(0);
    }
  });
});
