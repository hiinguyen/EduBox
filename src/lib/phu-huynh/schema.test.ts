import { describe, expect, it } from "vitest";
import { dashboardSearchParamsSchema } from "./schema";

describe("dashboardSearchParamsSchema", () => {
  it("accepts a missing child id", () => {
    expect(dashboardSearchParamsSchema.safeParse({}).success).toBe(true);
  });

  it("accepts a well formed child id", () => {
    const result = dashboardSearchParamsSchema.safeParse({ con: "child-nguyen-minh-anh" });

    expect(result.success).toBe(true);
  });

  it("rejects ids with unexpected characters", () => {
    const result = dashboardSearchParamsSchema.safeParse({ con: "../etc/passwd" });

    expect(result.success).toBe(false);
  });

  it("rejects repeated query parameters", () => {
    const result = dashboardSearchParamsSchema.safeParse({ con: ["a", "b"] });

    expect(result.success).toBe(false);
  });
});
