import { describe, expect, it } from "vitest";
import { getPrimaryNavForRole, getRoleSwitchItems, PRIMARY_NAV } from "./navigation";
import { SCREEN_ROLES } from "./auth/route-access";

describe("getRoleSwitchItems", () => {
  it("shows a student only the student target", () => {
    expect(getRoleSwitchItems("STUDENT").map((item) => item.href)).toEqual(["/hoc-tap"]);
  });

  it("shows a teacher only the teacher target", () => {
    expect(getRoleSwitchItems("TEACHER").map((item) => item.href)).toEqual(["/giao-vien"]);
  });

  it("shows a parent only the parent target", () => {
    expect(getRoleSwitchItems("PARENT").map((item) => item.href)).toEqual(["/phu-huynh"]);
  });
});

describe("getPrimaryNavForRole", () => {
  it("shows a student the learning and exam areas in sidebar order", () => {
    expect(getPrimaryNavForRole("STUDENT").map((item) => item.href)).toEqual([
      "/hoc-tap",
      "/thi-truc-tuyen",
    ]);
  });

  it("shows a teacher only the teacher workspace", () => {
    expect(getPrimaryNavForRole("TEACHER").map((item) => item.href)).toEqual(["/giao-vien"]);
  });

  it("shows a parent only the parent portal", () => {
    expect(getPrimaryNavForRole("PARENT").map((item) => item.href)).toEqual(["/phu-huynh"]);
  });

  it("never lists an area the route gate would reject for that role", () => {
    for (const role of ["STUDENT", "PARENT", "TEACHER"] as const) {
      for (const item of getPrimaryNavForRole(role)) {
        const allowed: readonly string[] = SCREEN_ROLES[item.href];
        expect(allowed).toContain(role);
      }
    }
  });

  it("covers every primary area with at least one role", () => {
    const listed = new Set(
      (["STUDENT", "PARENT", "TEACHER"] as const).flatMap((role) =>
        getPrimaryNavForRole(role).map((item) => item.href),
      ),
    );

    expect([...listed].sort()).toEqual(PRIMARY_NAV.map((item) => item.href).sort());
  });
});
