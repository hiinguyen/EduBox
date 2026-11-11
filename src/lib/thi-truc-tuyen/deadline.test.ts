import { describe, expect, it } from "vitest";
import { MS_PER_MINUTE } from "@/lib/format/time";
import { computeEndsAt } from "./deadline";

const NOW = new Date("2026-03-02T01:00:00.000Z");

describe("computeEndsAt", () => {
  it("adds the duration when there is no due date", () => {
    expect(computeEndsAt(NOW, 45, null).getTime()).toBe(NOW.getTime() + 45 * MS_PER_MINUTE);
  });

  it("uses the due date when it comes before the full duration", () => {
    const dueAt = new Date(NOW.getTime() + 10 * MS_PER_MINUTE);

    expect(computeEndsAt(NOW, 45, dueAt)).toEqual(dueAt);
  });

  it("keeps the full duration when the due date is later", () => {
    const dueAt = new Date(NOW.getTime() + 600 * MS_PER_MINUTE);

    expect(computeEndsAt(NOW, 45, dueAt).getTime()).toBe(NOW.getTime() + 45 * MS_PER_MINUTE);
  });
});
