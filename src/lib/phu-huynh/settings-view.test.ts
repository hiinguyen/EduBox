import { describe, expect, it } from "vitest";
import { buildLinkedDevices, buildSettings } from "./settings-view";

describe("buildSettings", () => {
  it("falls back to the defaults when the parent never saved settings", () => {
    const settings = buildSettings(null);

    expect(settings.map((setting) => [setting.id, setting.isEnabled])).toEqual([
      ["night-limit", true],
      ["instant-alerts", true],
    ]);
    expect(settings[0]?.description).toContain("23:30");
  });

  it("reflects stored values", () => {
    const settings = buildSettings({
      isNightLimitOn: false,
      nightLimitStartMin: 22 * 60,
      isInstantAlertOn: false,
    });

    expect(settings.map((setting) => setting.isEnabled)).toEqual([false, false]);
    expect(settings[0]?.description).toContain("22:00");
  });
});

describe("buildLinkedDevices", () => {
  it("joins device names", () => {
    expect(buildLinkedDevices(["iPad Air", "Laptop"]).label).toBe(
      "Thiết bị liên kết: iPad Air & Laptop",
    );
  });

  it("says so when no device is linked", () => {
    expect(buildLinkedDevices([]).label).toBe("Chưa có thiết bị liên kết");
  });
});
