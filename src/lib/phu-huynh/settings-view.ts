import { DEFAULT_NIGHT_LIMIT_START_MIN, MINUTES_PER_HOUR } from "./constants";
import type { CompanionSetting, LinkedDevices } from "./types";

const CLOCK_PAD_WIDTH = 2;

export function formatMinutesAsClock(minutesAfterMidnight: number): string {
  const pad = (value: number) => String(value).padStart(CLOCK_PAD_WIDTH, "0");
  return `${pad(Math.floor(minutesAfterMidnight / MINUTES_PER_HOUR))}:${pad(minutesAfterMidnight % MINUTES_PER_HOUR)}`;
}

export interface SettingsRow {
  readonly isNightLimitOn: boolean;
  readonly nightLimitStartMin: number;
  readonly isInstantAlertOn: boolean;
}

/** What a parent sees before ever touching the switches; mirrors the column defaults. */
export const DEFAULT_SETTINGS: SettingsRow = {
  isNightLimitOn: true,
  nightLimitStartMin: DEFAULT_NIGHT_LIMIT_START_MIN,
  isInstantAlertOn: true,
};

export function buildSettings(row: SettingsRow | null): readonly CompanionSetting[] {
  const settings = row ?? DEFAULT_SETTINGS;
  return [
    {
      id: "night-limit",
      icon: "bedtime",
      tone: "secondary",
      title: "Giới hạn giờ học ban đêm",
      description: `Khóa thiết bị học sau ${formatMinutesAsClock(settings.nightLimitStartMin)} để bảo vệ giấc ngủ`,
      isEnabled: settings.isNightLimitOn,
    },
    {
      id: "instant-alerts",
      icon: "mark_chat_read",
      tone: "tertiary",
      title: "Nhận thông báo Zalo / SMS",
      description: "Báo tức thì khi có điểm kiểm tra & nhận xét mới",
      isEnabled: settings.isInstantAlertOn,
    },
  ];
}

export function buildLinkedDevices(deviceNames: readonly string[]): LinkedDevices {
  const label =
    deviceNames.length > 0
      ? `Thiết bị liên kết: ${deviceNames.join(" & ")}`
      : "Chưa có thiết bị liên kết";
  return { label, actionLabel: "Quản lý" };
}
