import { describe, expect, it } from "vitest";
import { toActivityEntry, type ActivityRow } from "./activity";

/** 16:00 on 11/11/2026 in Vietnam (UTC+7). */
const NOW = new Date("2026-11-11T09:00:00Z");

const ROW: ActivityRow = {
  id: "act-1",
  kind: "EXAM_COMPLETED",
  title: "Hoàn thành bài thi thử",
  description: [{ text: "Đạt " }, { text: "8.5", isEmphasis: true }],
  tags: [{ label: "Đã chấm", tone: "neutral" }],
  occurredAt: new Date("2026-11-11T08:30:00Z"),
};

describe("toActivityEntry", () => {
  it("maps the kind to an icon and tone and formats the time", () => {
    const entry = toActivityEntry(ROW, NOW);

    expect(entry).toMatchObject({
      id: "act-1",
      icon: "assignment_turned_in",
      tone: "primary",
      timeLabel: "Hôm nay 15:30",
    });
    expect(entry?.description).toHaveLength(2);
  });

  it("returns null when the description JSON is malformed", () => {
    expect(toActivityEntry({ ...ROW, description: "plain text" }, NOW)).toBeNull();
  });

  it("returns null when a tag uses an unknown tone", () => {
    expect(toActivityEntry({ ...ROW, tags: [{ label: "x", tone: "neon" }] }, NOW)).toBeNull();
  });
});
