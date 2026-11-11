import { describe, expect, it } from "vitest";
import type { ChildProfile } from "./types";
import { currentAcademicYear, toChildOption, toTeacherNote } from "./view-model";

const CHILD: ChildProfile = {
  id: "child-1",
  fullName: "Nguyễn Minh Anh",
  givenName: "Minh Anh",
  className: "12A1",
  studentCode: "ES-2024-8892",
};

describe("toChildOption", () => {
  it("keeps only the fields the switcher displays", () => {
    expect(toChildOption(CHILD)).toEqual({
      id: "child-1",
      name: "Nguyễn Minh Anh",
      className: "12A1",
      studentCode: "ES-2024-8892",
    });
  });
});

describe("toTeacherNote", () => {
  const NOW = new Date("2026-11-11T09:00:00Z");

  it("marks the note acknowledged only when acknowledgedAt is set", () => {
    const base = {
      id: "n-1",
      subject: "Toán học",
      weekLabel: "Tuần 8",
      message: "Tốt",
      createdAt: new Date("2026-11-11T07:00:00Z"),
      teacherName: "Cô Hà",
    };

    expect(toTeacherNote({ ...base, acknowledgedAt: null }, "12A1", NOW).isAcknowledged).toBe(
      false,
    );
    const read = toTeacherNote({ ...base, acknowledgedAt: NOW }, "12A1", NOW);
    expect(read.isAcknowledged).toBe(true);
    expect(read.sentAgo).toBe("2 giờ trước");
    expect(read.role).toBe("Giáo viên bộ môn Toán học 12A1");
  });
});

describe("currentAcademicYear", () => {
  it("starts a new school year in September", () => {
    expect(currentAcademicYear(new Date("2026-09-01T03:00:00Z"))).toBe("2026-2027");
    expect(currentAcademicYear(new Date("2026-11-11T09:00:00Z"))).toBe("2026-2027");
  });

  it("keeps the previous school year until August", () => {
    expect(currentAcademicYear(new Date("2027-03-01T03:00:00Z"))).toBe("2026-2027");
  });

  it("switches at Vietnam midnight, not at UTC midnight", () => {
    expect(currentAcademicYear(new Date("2026-08-31T16:59:59Z"))).toBe("2025-2026");
    expect(currentAcademicYear(new Date("2026-08-31T17:00:00Z"))).toBe("2026-2027");
  });
});
