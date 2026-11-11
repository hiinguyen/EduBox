import { describe, expect, it } from "vitest";
import { getGivenName } from "./name";

describe("getGivenName", () => {
  it("drops the family name from a three word name", () => {
    expect(getGivenName("Nguyễn Minh Anh")).toBe("Minh Anh");
  });

  it("drops the family name from a two word name", () => {
    expect(getGivenName("Lê Hoa")).toBe("Hoa");
  });

  it("keeps a single word as is", () => {
    expect(getGivenName("Hoa")).toBe("Hoa");
  });

  it("collapses extra whitespace", () => {
    expect(getGivenName("  Trần   Gia  Bảo ")).toBe("Gia Bảo");
  });
});
