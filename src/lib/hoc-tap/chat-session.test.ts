import { describe, expect, it } from "vitest";
import { splitByHighlight } from "./chat-session";

describe("splitByHighlight", () => {
  it("splits text around the highlighted fragment", () => {
    expect(splitByHighlight("tính f'(x) nhé", "f'(x)")).toEqual([
      { text: "tính ", isHighlight: false },
      { text: "f'(x)", isHighlight: true },
      { text: " nhé", isHighlight: false },
    ]);
  });

  it("returns a single plain part when there is no highlight", () => {
    expect(splitByHighlight("xin chào", undefined)).toEqual([
      { text: "xin chào", isHighlight: false },
    ]);
  });

  it("returns a single plain part when the fragment is absent", () => {
    expect(splitByHighlight("xin chào", "f'(x)")).toEqual([
      { text: "xin chào", isHighlight: false },
    ]);
  });
});
