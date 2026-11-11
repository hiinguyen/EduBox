import { describe, expect, it } from "vitest";
import { buildMaterialFilters, materialFilterHref, parseMaterialFilter } from "./materials";

describe("parseMaterialFilter", () => {
  it("accepts a known subject", () => {
    expect(parseMaterialFilter("physics")).toBe("physics");
  });

  it.each([undefined, "", "biology", ["math", "physics"], 42])(
    "falls back to all for %j",
    (raw) => {
      expect(parseMaterialFilter(raw)).toBe("all");
    },
  );
});

describe("materialFilterHref", () => {
  it("links the all chip to the bare route and a subject to the query", () => {
    expect(materialFilterHref("all")).toBe("/hoc-tap");
    expect(materialFilterHref("math")).toBe("/hoc-tap?mon=math");
  });
});

describe("buildMaterialFilters", () => {
  it("lists all plus only the subjects present, in canonical order", () => {
    const options = buildMaterialFilters(["english", "math", "english"]);

    expect(options.map((option) => option.value)).toEqual(["all", "math", "english"]);
  });

  it("offers only the all chip when there are no materials", () => {
    expect(buildMaterialFilters([])).toEqual([{ value: "all", label: "Tất cả" }]);
  });
});
