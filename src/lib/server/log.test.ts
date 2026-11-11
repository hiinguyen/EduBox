import { afterEach, describe, expect, it, vi } from "vitest";
import { logServerError } from "./log";

afterEach(() => vi.restoreAllMocks());

function captured(spy: { mock: { calls: unknown[][] } }): string {
  return spy.mock.calls.map((call) => String(call[0])).join("");
}

describe("logServerError", () => {
  it("logs scope, error name, code and context ids", () => {
    const spy = vi.spyOn(process.stderr, "write").mockReturnValue(true);
    const error = Object.assign(new TypeError("boom"), { code: "P2002" });

    logServerError("exam.submit", error, { attemptId: "a1" });

    expect(JSON.parse(captured(spy))).toEqual({
      scope: "exam.submit",
      name: "TypeError",
      code: "P2002",
      attemptId: "a1",
    });
  });

  it("never logs the error message", () => {
    const spy = vi.spyOn(process.stderr, "write").mockReturnValue(true);

    logServerError("x", new Error("student answer: Nguyen Van A"));

    expect(captured(spy)).not.toContain("Nguyen");
  });

  it("handles non-Error throwables", () => {
    const spy = vi.spyOn(process.stderr, "write").mockReturnValue(true);

    logServerError("x", "string failure");

    expect(JSON.parse(captured(spy)).name).toBe("UnknownError");
  });
});
