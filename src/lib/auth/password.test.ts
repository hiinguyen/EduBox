import { describe, expect, it } from "vitest";
import { hashPassword, verifyPassword } from "./password";

describe("password hashing", () => {
  it("verifies the original password against its hash", async () => {
    const stored = await hashPassword("correct horse battery");

    expect(await verifyPassword(stored, "correct horse battery")).toBe(true);
  });

  it("rejects a wrong password", async () => {
    const stored = await hashPassword("correct horse battery");

    expect(await verifyPassword(stored, "wrong password!")).toBe(false);
  });

  it("produces a different salted hash each time", async () => {
    const [first, second] = await Promise.all([
      hashPassword("same-password"),
      hashPassword("same-password"),
    ]);

    expect(first).not.toBe(second);
    expect(first.startsWith("$argon2id$")).toBe(true);
  });

  it("treats a malformed stored hash as a failed verification", async () => {
    expect(await verifyPassword("not-a-hash", "whatever-password")).toBe(false);
  });
});
