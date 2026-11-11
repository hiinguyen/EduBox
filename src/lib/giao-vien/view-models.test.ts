import { describe, expect, it } from "vitest";
import {
  toInsights,
  toLecture,
  toSubmissionDetail,
  toSubmissionRow,
  toTeacher,
  type LectureSource,
  type SubmissionDetailSource,
} from "./view-models";

const NOW = new Date("2026-11-11T10:00:00Z");

function makeSubmission(overrides: Partial<SubmissionDetailSource> = {}): SubmissionDetailSource {
  return {
    id: "s1",
    code: "#TN-982",
    multipleChoiceScore: 6,
    submittedAt: new Date("2026-11-11T07:22:18Z"),
    student: { studentCode: "120148", user: { name: "Lê Hoàng Nam" } },
    grade: null,
    aiSuggestion: null,
    ...overrides,
  };
}

describe("toTeacher", () => {
  it("derives the short form of address from the full name", () => {
    const teacher = toTeacher({
      name: "Cô Nguyễn Thu Hà",
      department: "Tổ Toán",
      subjectLabel: "Toán học 12",
      termLabel: "Học kỳ II · 2024",
    });

    expect(teacher.shortName).toBe("cô Hà");
    expect(teacher.displayName).toBe("Cô Nguyễn Thu Hà");
  });
});

describe("toSubmissionRow", () => {
  it("is pending when there is no grade", () => {
    const row = toSubmissionRow(makeSubmission(), NOW);

    expect(row.essayScore).toBeNull();
    expect(row.submittedAtLabel).toBe("14:22 Hôm nay");
    expect(row.studentNumber).toBe("120148");
  });

  it("carries the essay score of the grade", () => {
    const row = toSubmissionRow(
      makeSubmission({ grade: { essayScore: 3.5, feedback: null, notifiedAt: null } }),
      NOW,
    );

    expect(row.essayScore).toBe(3.5);
  });

  it("exposes only the displayed fields", () => {
    const row = toSubmissionRow(makeSubmission(), NOW);

    expect(Object.keys(row).sort()).toEqual([
      "code",
      "essayScore",
      "id",
      "multipleChoiceScore",
      "studentName",
      "studentNumber",
      "submittedAtLabel",
    ]);
  });
});

describe("toSubmissionDetail", () => {
  it("validates the cached AI suggestion and drops malformed JSON", () => {
    const valid = { comment: "c", suggestedScore: 3, feedbackDraft: "f" };

    expect(toSubmissionDetail(makeSubmission({ aiSuggestion: valid }), NOW).aiSuggestion).toEqual(
      valid,
    );
    expect(
      toSubmissionDetail(makeSubmission({ aiSuggestion: { x: 1 } }), NOW).aiSuggestion,
    ).toBeNull();
  });

  it("reports feedback and whether parents were notified", () => {
    const grade = { essayScore: 3, feedback: "Tốt", notifiedAt: NOW };

    const detail = toSubmissionDetail(makeSubmission({ grade }), NOW);

    expect(detail.feedback).toBe("Tốt");
    expect(detail.isParentNotified).toBe(true);
    expect(detail.submittedTimeLabel).toBe("14:22:18");
  });
});

describe("toLecture", () => {
  const source: LectureSource = {
    id: "l1",
    title: "Chuyên đề 04",
    subtitle: null,
    topic: "Giải tích 12",
    durationSeconds: 2295,
    viewCount: 284,
    ratingAverage: 4.9,
    ratingCount: 86,
    status: "PUBLISHED",
    classes: [{ class: { name: "12A1" } }, { class: { name: "12A2" } }],
  };

  it("maps a published lecture with a rating", () => {
    expect(toLecture(source)).toMatchObject({
      subtitle: "Giải tích 12",
      durationLabel: "38 phút 15 giây",
      classNames: ["12A1", "12A2"],
      rating: { average: 4.9, count: 86 },
      status: "published",
    });
  });

  it("has no rating when nobody rated it", () => {
    const lecture = toLecture({ ...source, ratingAverage: null, ratingCount: 0, status: "DRAFT" });

    expect(lecture.rating).toBeNull();
    expect(lecture.status).toBe("draft");
  });
});

describe("toInsights", () => {
  it("maps tones and remediation text", () => {
    const insights = toInsights({
      scannedSubmissions: 42,
      remediationIntro: "a",
      remediationLecture: "b",
      remediationOutro: "c",
      gaps: [{ id: "g", topic: "t", percent: 68, tone: "MASTERED", note: "n" }],
    });

    expect(insights.gaps[0]?.tone).toBe("mastered");
    expect(insights.remediation).toEqual({ intro: "a", lectureTitle: "b", outro: "c" });
  });
});
