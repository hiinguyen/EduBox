import { describe, expect, it } from "vitest";
import { MAX_ID_LENGTH } from "./constants";
import { buildWorkspaceHref, parseWorkspaceQuery } from "./query";

describe("parseWorkspaceQuery", () => {
  it("reads every supported parameter", () => {
    const result = parseWorkspaceQuery({
      lop: "c1",
      bai: "a1",
      "bai-nop": "s1",
      trang: "3",
      "bai-giang": "2",
    });

    expect(result).toEqual({
      classId: "c1",
      assessmentId: "a1",
      submissionId: "s1",
      page: 3,
      lecturePage: 2,
    });
  });

  it("returns undefined for every missing parameter", () => {
    expect(parseWorkspaceQuery({})).toEqual({
      classId: undefined,
      assessmentId: undefined,
      submissionId: undefined,
      page: undefined,
      lecturePage: undefined,
    });
  });

  it("drops malformed pages instead of throwing", () => {
    expect(parseWorkspaceQuery({ trang: "abc" }).page).toBeUndefined();
    expect(parseWorkspaceQuery({ trang: "0" }).page).toBeUndefined();
    expect(parseWorkspaceQuery({ trang: "-2" }).page).toBeUndefined();
    expect(parseWorkspaceQuery({ trang: "1.5" }).page).toBeUndefined();
    expect(parseWorkspaceQuery({ "bai-giang": "x" }).lecturePage).toBeUndefined();
  });

  it("drops empty and oversized ids", () => {
    const result = parseWorkspaceQuery({ lop: "  ", bai: "x".repeat(MAX_ID_LENGTH + 1) });

    expect(result.classId).toBeUndefined();
    expect(result.assessmentId).toBeUndefined();
  });

  it("uses the first value when a parameter is repeated", () => {
    expect(parseWorkspaceQuery({ lop: ["first", "second"] }).classId).toBe("first");
  });
});

describe("buildWorkspaceHref", () => {
  it("returns the bare path when nothing is selected", () => {
    expect(buildWorkspaceHref({})).toBe("/giao-vien");
  });

  it("omits the first page and keeps later pages", () => {
    expect(buildWorkspaceHref({ classId: "c1", page: 1 })).toBe("/giao-vien?lop=c1");
    expect(buildWorkspaceHref({ classId: "c1", page: 2, lecturePage: 3 })).toBe(
      "/giao-vien?lop=c1&trang=2&bai-giang=3",
    );
  });

  it("encodes ids", () => {
    expect(buildWorkspaceHref({ submissionId: "a&b" })).toBe("/giao-vien?bai-nop=a%26b");
  });
});
