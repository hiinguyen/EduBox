import { describe, expect, it } from "vitest";
import { EnvError, parseEnv } from "./env";

const SECRET = "x".repeat(32);
const VALID = {
  DATABASE_URL: "postgresql://u:p@localhost:5432/db",
  AUTH_SECRET: SECRET,
};

describe("parseEnv", () => {
  it("returns typed values when the environment is valid", () => {
    const env = parseEnv({ ...VALID, AI_MODEL: "model-a" });

    expect(env.DATABASE_URL).toBe(VALID.DATABASE_URL);
    expect(env.AI_MODEL).toBe("model-a");
    expect(env.NODE_ENV).toBe("development");
  });

  it("treats empty optional AI variables as undefined", () => {
    const env = parseEnv({ ...VALID, OPENCODE_API_KEY: "", OPENCODE_BASE_URL: "" });

    expect(env.OPENCODE_API_KEY).toBeUndefined();
    expect(env.OPENCODE_BASE_URL).toBeUndefined();
  });

  it("throws a clear error naming each missing variable", () => {
    expect(() => parseEnv({})).toThrow(EnvError);
    expect(() => parseEnv({})).toThrow(/DATABASE_URL/);
    expect(() => parseEnv({})).toThrow(/AUTH_SECRET/);
  });

  it("never includes received secret values in the error message", () => {
    const leaked = "super-secret-short";

    expect(() => parseEnv({ ...VALID, AUTH_SECRET: leaked })).toThrow(EnvError);
    try {
      parseEnv({ ...VALID, AUTH_SECRET: leaked });
    } catch (error) {
      expect(String(error)).not.toContain(leaked);
    }
  });
});

describe("parseEnv transport and proxy rules", () => {
  it("defaults TRUSTED_PROXY_HOPS to 0 and parses an integer", () => {
    expect(parseEnv(VALID).TRUSTED_PROXY_HOPS).toBe(0);
    expect(parseEnv({ ...VALID, TRUSTED_PROXY_HOPS: "2" }).TRUSTED_PROXY_HOPS).toBe(2);
  });

  it("rejects a negative or fractional TRUSTED_PROXY_HOPS", () => {
    expect(() => parseEnv({ ...VALID, TRUSTED_PROXY_HOPS: "-1" })).toThrow(/TRUSTED_PROXY_HOPS/);
    expect(() => parseEnv({ ...VALID, TRUSTED_PROXY_HOPS: "1.5" })).toThrow(/TRUSTED_PROXY_HOPS/);
  });

  it("requires https for AUTH_URL and OPENCODE_BASE_URL in production", () => {
    const production = { ...VALID, NODE_ENV: "production" };

    expect(() => parseEnv({ ...production, AUTH_URL: "http://edubox.vn" })).toThrow(/AUTH_URL/);
    expect(() => parseEnv({ ...production, OPENCODE_BASE_URL: "http://ai.test" })).toThrow(
      /OPENCODE_BASE_URL/,
    );
    expect(
      parseEnv({
        ...production,
        AUTH_URL: "https://edubox.vn",
        OPENCODE_BASE_URL: "https://ai.test",
      }).AUTH_URL,
    ).toBe("https://edubox.vn");
  });

  it("accepts plain http on loopback hosts in production", () => {
    const production = { ...VALID, NODE_ENV: "production" };

    expect(parseEnv({ ...production, AUTH_URL: "http://localhost:3000" }).AUTH_URL).toBe(
      "http://localhost:3000",
    );
    expect(parseEnv({ ...production, AUTH_URL: "http://127.0.0.1:3000" }).AUTH_URL).toBe(
      "http://127.0.0.1:3000",
    );
  });

  it("rejects http on lookalike hosts in production", () => {
    const production = { ...VALID, NODE_ENV: "production" };

    expect(() => parseEnv({ ...production, AUTH_URL: "http://localhost.evil.test" })).toThrow(
      /AUTH_URL/,
    );
  });

  it("allows http URLs outside production", () => {
    expect(parseEnv({ ...VALID, AUTH_URL: "http://localhost:3000" }).AUTH_URL).toBe(
      "http://localhost:3000",
    );
  });
});
