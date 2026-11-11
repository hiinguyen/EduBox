import { describe, expect, it } from "vitest";
import { clientIpFromHeaders, hashKeyPart } from "./sign-in-keys";

const headers = (forwarded: string) => new Headers({ "x-forwarded-for": forwarded });

describe("clientIpFromHeaders", () => {
  it("ignores forwarding headers when no proxy is trusted", () => {
    expect(clientIpFromHeaders(headers("1.1.1.1"), 0)).toBeNull();
  });

  it("takes the last entry for one trusted hop, ignoring forged leading entries", () => {
    expect(clientIpFromHeaders(headers("6.6.6.6, 7.7.7.7, 203.0.113.9"), 1)).toBe("203.0.113.9");
  });

  it("counts N entries from the right", () => {
    expect(clientIpFromHeaders(headers("6.6.6.6, 203.0.113.9, 10.0.0.1"), 2)).toBe("203.0.113.9");
  });

  it("falls back to a shared bucket when the header is shorter than the trusted chain", () => {
    expect(clientIpFromHeaders(headers("6.6.6.6"), 2)).toBe("unknown");
    expect(clientIpFromHeaders(new Headers(), 1)).toBe("unknown");
  });
});

describe("hashKeyPart", () => {
  it("is deterministic, fixed length and hides the raw value", () => {
    const hash = hashKeyPart("secret", "minh.anh@edubox.test");

    expect(hash).toBe(hashKeyPart("secret", "minh.anh@edubox.test"));
    expect(hash).toMatch(/^[0-9a-f]{64}$/);
    expect(hash).not.toContain("minh");
  });

  it("bounds the length of arbitrarily long input", () => {
    expect(hashKeyPart("secret", "a".repeat(100_000))).toHaveLength(64);
  });

  it("depends on the secret", () => {
    expect(hashKeyPart("one", "x")).not.toBe(hashKeyPart("two", "x"));
  });
});
