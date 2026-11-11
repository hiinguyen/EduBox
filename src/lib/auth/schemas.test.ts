import { describe, expect, it } from "vitest";
import { signInSchema } from "./schemas";

describe("signInSchema", () => {
  it("normalises the email to trimmed lower case", () => {
    const parsed = signInSchema.parse({
      email: "  Minh.Anh@EduBox.Test ",
      password: "password-123",
    });

    expect(parsed.email).toBe("minh.anh@edubox.test");
  });

  it("rejects an invalid email", () => {
    expect(signInSchema.safeParse({ email: "nope", password: "password-123" }).success).toBe(false);
  });

  it("rejects a too short or too long password", () => {
    expect(signInSchema.safeParse({ email: "a@b.co", password: "short" }).success).toBe(false);
    expect(signInSchema.safeParse({ email: "a@b.co", password: "x".repeat(129) }).success).toBe(
      false,
    );
  });
});
