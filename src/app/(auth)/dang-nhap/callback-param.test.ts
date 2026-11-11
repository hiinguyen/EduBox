import { describe, expect, it } from "vitest";
import { readCallbackParam } from "./callback-param";

describe("readCallbackParam", () => {
  it("returns a same-origin path unchanged", () => {
    expect(readCallbackParam("/hoc-tap?tab=1")).toBe("/hoc-tap?tab=1");
  });

  it("uses the first value when the parameter repeats", () => {
    expect(readCallbackParam(["/phu-huynh", "/giao-vien"])).toBe("/phu-huynh");
  });

  it("returns null when the parameter is missing", () => {
    expect(readCallbackParam(undefined)).toBeNull();
  });

  it("drops protocol-relative and absolute URLs", () => {
    expect(readCallbackParam("//evil.example")).toBeNull();
    expect(readCallbackParam("https://evil.example")).toBeNull();
  });
});
