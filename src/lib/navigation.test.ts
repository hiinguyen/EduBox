import { describe, expect, it } from "vitest";
import { isActivePath, PRIMARY_NAV, ROLE_SWITCHER, SYSTEM_NAV } from "./navigation";
import { SCREENS } from "./screens";

describe("isActivePath", () => {
  it("returns true for the exact path", () => {
    expect(isActivePath("/hoc-tap", "/hoc-tap")).toBe(true);
  });

  it("returns true for a nested path below the href", () => {
    expect(isActivePath("/hoc-tap/bai-giang/12", "/hoc-tap")).toBe(true);
  });

  it("returns false when the path only shares a prefix", () => {
    expect(isActivePath("/hoc-tap-nang-cao", "/hoc-tap")).toBe(false);
  });

  it("ignores trailing slashes", () => {
    expect(isActivePath("/hoc-tap/", "/hoc-tap")).toBe(true);
    expect(isActivePath("/hoc-tap", "/hoc-tap/")).toBe(true);
  });
});

describe("navigation data", () => {
  it("lists the four primary areas in sidebar order", () => {
    expect(PRIMARY_NAV.map((item) => item.href)).toEqual([
      "/hoc-tap",
      "/thi-truc-tuyen",
      "/giao-vien",
      "/phu-huynh",
    ]);
  });

  it("takes primary labels from the screen catalogue", () => {
    for (const item of PRIMARY_NAV) {
      expect(item.label).toBe(SCREENS.find((screen) => screen.href === item.href)?.title);
    }
  });

  it("keeps role switcher links inside the primary areas", () => {
    const primaryHrefs = new Set(PRIMARY_NAV.map((item) => item.href));

    for (const role of ROLE_SWITCHER) {
      expect(primaryHrefs.has(role.href)).toBe(true);
    }
  });

  it("gives every system item a unique id and no href", () => {
    const ids = SYSTEM_NAV.map((item) => item.id);

    expect(new Set(ids).size).toBe(SYSTEM_NAV.length);
    for (const item of SYSTEM_NAV) {
      expect("href" in item).toBe(false);
    }
  });

  it("gives every navigation item an icon and a label", () => {
    for (const item of [...PRIMARY_NAV, ...SYSTEM_NAV]) {
      expect(item.icon.length).toBeGreaterThan(0);
      expect(item.label.length).toBeGreaterThan(0);
    }
  });
});
