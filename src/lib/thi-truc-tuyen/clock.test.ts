import { describe, expect, it } from "vitest";
import { getRemainingMs } from "./countdown";
import { getClockOffsetMs, toServerTime } from "./clock";

const SERVER_NOW = 1_000_000;

describe("clock skew correction", () => {
  it("measures a browser clock that runs behind the server as a positive offset", () => {
    expect(getClockOffsetMs(SERVER_NOW, SERVER_NOW - 90_000)).toBe(90_000);
  });

  it("measures a browser clock that runs ahead of the server as a negative offset", () => {
    expect(getClockOffsetMs(SERVER_NOW, SERVER_NOW + 5_000)).toBe(-5_000);
  });

  it("converts browser time to server time", () => {
    const offset = getClockOffsetMs(SERVER_NOW, SERVER_NOW - 90_000);

    expect(toServerTime(SERVER_NOW - 90_000 + 2_000, offset)).toBe(SERVER_NOW + 2_000);
  });

  it("gives the same remaining time whatever the browser clock says", () => {
    const endsAt = SERVER_NOW + 60_000;
    const skewed = SERVER_NOW + 3_600_000;
    const offset = getClockOffsetMs(SERVER_NOW, skewed);

    expect(getRemainingMs(endsAt, toServerTime(skewed + 10_000, offset))).toBe(50_000);
  });
});
