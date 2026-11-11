import { describe, expect, it } from "vitest";
import {
  buildSignInUrl,
  decideRouteAccess,
  resolvePostLoginPath,
  sanitizeCallbackPath,
} from "./route-access";

describe("decideRouteAccess", () => {
  it("asks anonymous visitors to sign in on protected screens", () => {
    expect(decideRouteAccess("/hoc-tap", null)).toEqual({ type: "login" });
    expect(decideRouteAccess("/giao-vien/lop", null)).toEqual({ type: "login" });
  });

  it("allows a student on hoc-tap and thi-truc-tuyen only", () => {
    expect(decideRouteAccess("/hoc-tap", "STUDENT").type).toBe("allow");
    expect(decideRouteAccess("/thi-truc-tuyen", "STUDENT").type).toBe("allow");
    expect(decideRouteAccess("/giao-vien", "STUDENT").type).toBe("forbidden");
    expect(decideRouteAccess("/phu-huynh", "STUDENT").type).toBe("forbidden");
  });

  it("restricts parent and teacher screens to their own role", () => {
    expect(decideRouteAccess("/phu-huynh", "PARENT").type).toBe("allow");
    expect(decideRouteAccess("/giao-vien", "PARENT").type).toBe("forbidden");
    expect(decideRouteAccess("/giao-vien", "TEACHER").type).toBe("allow");
    expect(decideRouteAccess("/hoc-tap", "TEACHER").type).toBe("forbidden");
  });

  it("does not treat a lookalike prefix as a protected screen", () => {
    expect(decideRouteAccess("/hoc-tap-extra", null)).toEqual({ type: "allow" });
  });

  it("leaves public routes open", () => {
    expect(decideRouteAccess("/", null).type).toBe("allow");
    expect(decideRouteAccess("/dang-nhap", null).type).toBe("allow");
  });
});

describe("sanitizeCallbackPath", () => {
  it.each([null, undefined, "", "https://evil.test", "//evil.test", "/\\evil", "hoc-tap"])(
    "rejects %s",
    (value) => {
      expect(sanitizeCallbackPath(value)).toBeNull();
    },
  );

  it("keeps a same-origin path with query", () => {
    expect(sanitizeCallbackPath("/hoc-tap?x=1")).toBe("/hoc-tap?x=1");
  });
});

describe("resolvePostLoginPath", () => {
  it("sends each role to its own home by default", () => {
    expect(resolvePostLoginPath("STUDENT", null)).toBe("/hoc-tap");
    expect(resolvePostLoginPath("PARENT", null)).toBe("/phu-huynh");
    expect(resolvePostLoginPath("TEACHER", null)).toBe("/giao-vien");
  });

  it("honours a callback the role may open", () => {
    expect(resolvePostLoginPath("STUDENT", "/thi-truc-tuyen")).toBe("/thi-truc-tuyen");
  });

  it("ignores a callback the role may not open", () => {
    expect(resolvePostLoginPath("STUDENT", "/giao-vien")).toBe("/hoc-tap");
  });

  it("ignores an external callback", () => {
    expect(resolvePostLoginPath("TEACHER", "https://evil.test")).toBe("/giao-vien");
  });
});

describe("buildSignInUrl", () => {
  it("encodes the callback path", () => {
    expect(buildSignInUrl("/hoc-tap?a=1")).toBe("/dang-nhap?callbackUrl=%2Fhoc-tap%3Fa%3D1");
  });

  it("drops an unsafe callback", () => {
    expect(buildSignInUrl("//evil.test")).toBe("/dang-nhap");
  });
});
