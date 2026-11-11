import { describe, expect, it } from "vitest";
import { buildPoints, indexToX, scoreToY, toAreaPath, toPointsAttribute } from "./chart";

describe("scoreToY", () => {
  it("maps the top and bottom of the score scale to the plot edges", () => {
    expect(scoreToY(10)).toBe(30);
    expect(scoreToY(4)).toBe(165);
  });

  it("places an intermediate score proportionally", () => {
    expect(scoreToY(7)).toBe(97.5);
  });

  it("clamps scores outside the scale", () => {
    expect(scoreToY(12)).toBe(30);
    expect(scoreToY(1)).toBe(165);
  });
});

describe("indexToX", () => {
  it("spreads points evenly between the plot edges", () => {
    expect(indexToX(0, 6)).toBe(60);
    expect(indexToX(5, 6)).toBe(600);
    expect(indexToX(1, 6)).toBe(168);
  });

  it("uses the left edge when there is a single point", () => {
    expect(indexToX(0, 1)).toBe(60);
  });
});

describe("buildPoints", () => {
  it("returns an empty list when there are no scores", () => {
    expect(buildPoints([])).toEqual([]);
  });

  it("converts each score to chart coordinates", () => {
    expect(buildPoints([10, 4])).toEqual([
      { x: 60, y: 30 },
      { x: 600, y: 165 },
    ]);
  });
});

describe("toPointsAttribute", () => {
  it("joins coordinates without trailing zeros", () => {
    const points = buildPoints([10, 8.5]);

    expect(toPointsAttribute(points)).toBe("60,30 600,63.75");
  });
});

describe("toAreaPath", () => {
  it("closes the line down to the plot floor", () => {
    const points = buildPoints([10, 4]);

    expect(toAreaPath(points)).toBe("M60,30 L600,165 L600,165 L60,165 Z");
  });

  it("returns an empty path when there are no points", () => {
    expect(toAreaPath([])).toBe("");
  });
});
