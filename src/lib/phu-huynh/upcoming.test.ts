import { describe, expect, it } from "vitest";
import { formatDueLabel, toUpcomingTask, type UpcomingRow } from "./upcoming";

/** 16:00 on 11/11/2026 in Vietnam (UTC+7). */
const NOW = new Date("2026-11-11T09:00:00Z");

const ROW: UpcomingRow = {
  id: "a-1",
  kind: "HOMEWORK",
  title: "Bài tập Hóa học",
  subtitle: null,
  className: "12A1",
  dueAt: new Date("2026-11-12T03:00:00Z"),
};

describe("toUpcomingTask", () => {
  it("flags deadlines within a day as urgent with an hour countdown", () => {
    const task = toUpcomingTask(ROW, NOW);

    expect(task.isUrgent).toBe(true);
    expect(task.badge).toEqual({ kind: "countdown", value: "18H", caption: "Hạn chót" });
    expect(task.dueLabel).toBe("Ngày mai 10:00");
  });

  it("uses a kind icon for later deadlines", () => {
    const task = toUpcomingTask(
      { ...ROW, kind: "EXAM", dueAt: new Date("2026-11-14T00:30:00Z") },
      NOW,
    );

    expect(task.isUrgent).toBe(false);
    expect(task.badge).toEqual({ kind: "icon", icon: "event_note", caption: "Kỳ thi" });
  });

  it("falls back to the class name when there is no subtitle", () => {
    expect(toUpcomingTask(ROW, NOW).subtitle).toBe("Lớp 12A1");
    expect(toUpcomingTask({ ...ROW, subtitle: "15 câu" }, NOW).subtitle).toBe("15 câu");
  });
});

describe("formatDueLabel", () => {
  it("labels today, tomorrow and later days in Vietnam time", () => {
    expect(formatDueLabel(new Date("2026-11-11T14:00:00Z"), NOW)).toBe("Hôm nay 21:00");
    expect(formatDueLabel(new Date("2026-11-12T14:00:00Z"), NOW)).toBe("Ngày mai 21:00");
    expect(formatDueLabel(new Date("2026-11-14T00:30:00Z"), NOW)).toBe("14/11 07:30");
  });

  it("uses the Vietnam day when the server day differs (23:00 UTC is already tomorrow)", () => {
    const lateUtc = new Date("2026-11-11T23:00:00Z");

    expect(formatDueLabel(new Date("2026-11-12T15:00:00Z"), lateUtc)).toBe("Hôm nay 22:00");
    expect(formatDueLabel(new Date("2026-11-13T02:00:00Z"), lateUtc)).toBe("Ngày mai 09:00");
  });

  it("treats 17:00 UTC as the start of the next Vietnam day", () => {
    const midnightVn = new Date("2026-11-11T17:00:00Z");

    expect(formatDueLabel(new Date("2026-11-12T10:00:00Z"), midnightVn)).toBe("Hôm nay 17:00");
  });
});
