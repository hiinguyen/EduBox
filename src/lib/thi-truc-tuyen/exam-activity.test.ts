import { describe, expect, it } from "vitest";
import { buildExamActivity } from "./exam-activity";

const BASE = {
  title: "Toán 12",
  status: "SUBMITTED",
  score: 7.5,
  correctCount: 3,
  totalCount: 4,
  isComplete: true,
} as const;

describe("buildExamActivity", () => {
  it("reports the score and correct count for a fully graded exam", () => {
    const activity = buildExamActivity(BASE);

    expect(activity.kind).toBe("EXAM_COMPLETED");
    expect(activity.title).toBe("Hoàn thành bài thi Toán 12");
    expect(activity.description).toEqual([
      { text: "Đạt kết quả " },
      { text: "7.5 điểm", isEmphasis: true },
      { text: " (3/4 câu đúng)." },
    ]);
    expect(activity.tags).toEqual([{ label: "Đã chấm tự động", tone: "neutral" }]);
  });

  it("says the exam awaits the teacher when an essay part is left", () => {
    const activity = buildExamActivity({ ...BASE, isComplete: false });

    expect(JSON.stringify(activity.description)).not.toContain("điểm");
    expect(activity.tags[0]?.label).toBe("Chờ giáo viên chấm");
  });

  it("marks an expired attempt as submitted automatically", () => {
    const activity = buildExamActivity({ ...BASE, status: "EXPIRED" });

    expect(activity.title).toBe("Hết giờ làm bài Toán 12");
    expect(activity.tags.map((tag) => tag.label)).toContain("Nộp tự động khi hết giờ");
  });
});
