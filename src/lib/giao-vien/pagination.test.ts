import { describe, expect, it } from "vitest";
import { pageOfIndex, paginate } from "./pagination";

describe("paginate", () => {
  it("returns a single empty page when there are no items", () => {
    const result = paginate(0, 1, 10);

    expect(result).toMatchObject({ page: 1, totalPages: 1, from: 0, to: 0, hasNext: false });
    expect(result.hasPrevious).toBe(false);
  });

  it("describes the first page of several", () => {
    const result = paginate(25, 1, 10);

    expect(result).toMatchObject({ totalPages: 3, from: 1, to: 10, skip: 0, hasNext: true });
    expect(result.hasPrevious).toBe(false);
  });

  it("shortens the last page to the remaining items", () => {
    const result = paginate(25, 3, 10);

    expect(result).toMatchObject({ page: 3, from: 21, to: 25, skip: 20, hasNext: false });
    expect(result.hasPrevious).toBe(true);
  });

  it("clamps an out-of-range page to the last page", () => {
    expect(paginate(25, 99, 10).page).toBe(3);
  });

  it("clamps zero, negative and non-finite pages to the first page", () => {
    expect(paginate(25, 0, 10).page).toBe(1);
    expect(paginate(25, -4, 10).page).toBe(1);
    expect(paginate(25, Number.NaN, 10).page).toBe(1);
  });

  it("does not add an empty page when the total is an exact multiple", () => {
    expect(paginate(20, 2, 10)).toMatchObject({ totalPages: 2, to: 20, hasNext: false });
  });
});

describe("pageOfIndex", () => {
  it("maps the number of preceding items to the page that holds the item", () => {
    expect(pageOfIndex(0, 10)).toBe(1);
    expect(pageOfIndex(9, 10)).toBe(1);
    expect(pageOfIndex(10, 10)).toBe(2);
    expect(pageOfIndex(-3, 10)).toBe(1);
  });
});
