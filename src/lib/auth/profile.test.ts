import { describe, expect, it } from "vitest";
import { MissingProfileError, profileIdForRole } from "./profile";

const NONE = { studentProfile: null, parentProfile: null, teacherProfile: null };

describe("profileIdForRole", () => {
  it("returns the profile that matches the role even when another profile exists", () => {
    const profiles = { ...NONE, studentProfile: { id: "s1" }, teacherProfile: { id: "t1" } };

    expect(profileIdForRole("TEACHER", profiles)).toBe("t1");
    expect(profileIdForRole("STUDENT", profiles)).toBe("s1");
  });

  it("throws a clear error when the matching profile is missing", () => {
    const profiles = { ...NONE, studentProfile: { id: "s1" } };

    expect(() => profileIdForRole("PARENT", profiles)).toThrow(MissingProfileError);
    expect(() => profileIdForRole("PARENT", profiles)).toThrow(/PARENT.*parent profile/);
  });
});
