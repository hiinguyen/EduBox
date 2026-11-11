import { afterAll, beforeAll, describe, expect, it } from "vitest";
import { db } from "@/lib/db";
import { createTaggedWorld, TEST_PASSWORD, type TestWorld } from "@/test/world";
import { verifyCredentials } from "./credentials";

let world: TestWorld;
let cleanup: () => Promise<void>;
let tag: string;

beforeAll(async () => {
  ({ world, cleanup, tag } = await createTaggedWorld());
});

afterAll(async () => {
  await cleanup();
  await db.$disconnect();
});

describe("verifyCredentials", () => {
  it("returns the user and role for a correct email and password", async () => {
    const user = await verifyCredentials({ email: world.studentAEmail, password: TEST_PASSWORD });

    expect(user?.role).toBe("STUDENT");
    expect(user).not.toHaveProperty("passwordHash");
  });

  it("matches the email case-insensitively", async () => {
    const user = await verifyCredentials({
      email: world.studentAEmail.toUpperCase(),
      password: TEST_PASSWORD,
    });

    expect(user?.role).toBe("STUDENT");
  });

  it("returns null for a wrong password", async () => {
    const user = await verifyCredentials({
      email: world.studentAEmail,
      password: "wrong-password",
    });

    expect(user).toBeNull();
  });

  it("returns null for an unknown email", async () => {
    const user = await verifyCredentials({ email: "nobody@test.local", password: TEST_PASSWORD });

    expect(user).toBeNull();
  });

  it("returns null for malformed input", async () => {
    expect(await verifyCredentials({ email: 42, password: null })).toBeNull();
  });

  it("returns null for an account that has no credential row", async () => {
    const email = `nocred.${tag}@test.local`;
    await db.user.create({ data: { email, name: "n", role: "STUDENT" } });

    expect(await verifyCredentials({ email, password: TEST_PASSWORD })).toBeNull();
  });
});
