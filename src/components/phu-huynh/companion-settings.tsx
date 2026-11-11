"use client";

import { useState } from "react";
import { DisabledNavItem } from "@/components/app-shell/disabled-nav-item";
import { Icon } from "@/components/ui/icon";
import { SectionPanel } from "@/components/ui/section-panel";
import { setCompanionSettingAction } from "@/lib/phu-huynh/actions";
import { DEFAULT_ERROR_MESSAGES } from "@/lib/server/action-result";
import { SETTING_IDS } from "@/lib/phu-huynh/schema";
import type { CompanionSetting, LinkedDevices } from "@/lib/phu-huynh/types";
import { TONE_TEXT_CLASS } from "@/lib/ui/tone";

type EnabledById = Readonly<Record<string, boolean>>;

interface SettingSwitchProps {
  readonly setting: CompanionSetting;
  readonly isEnabled: boolean;
  readonly isPending: boolean;
  readonly onChange: (isEnabled: boolean) => void;
}

function SettingSwitch({ setting, isEnabled, isPending, onChange }: SettingSwitchProps) {
  return (
    <label className="relative inline-flex shrink-0 cursor-pointer items-center">
      <input
        type="checkbox"
        role="switch"
        checked={isEnabled}
        disabled={isPending}
        onChange={(event) => onChange(event.target.checked)}
        aria-label={setting.title}
        className="peer sr-only"
      />
      <span className="h-6 w-11 rounded-full bg-surface-container-highest transition-colors after:absolute after:left-[2px] after:top-[2px] after:h-5 after:w-5 after:rounded-full after:border after:border-outline-variant after:bg-surface-container-lowest after:transition-all after:content-[''] peer-checked:bg-primary peer-checked:after:translate-x-full peer-checked:after:border-surface-container-lowest peer-focus-visible:outline-2 peer-focus-visible:outline-offset-2 peer-focus-visible:outline-primary" />
    </label>
  );
}

function SettingRow({ setting, isEnabled, isPending, onChange }: SettingSwitchProps) {
  return (
    <li className="flex items-center justify-between gap-space-sm">
      <div className="flex items-start gap-space-xs">
        <Icon
          name={setting.icon}
          className={`mt-0.5 text-[20px] ${TONE_TEXT_CLASS[setting.tone]}`}
        />
        <div>
          <span className="block font-label-md text-label-md font-medium text-on-surface">
            {setting.title}
          </span>
          <span className="font-body-sm text-body-sm text-on-surface-variant">
            {setting.description}
          </span>
        </div>
      </div>
      <SettingSwitch
        setting={setting}
        isEnabled={isEnabled}
        isPending={isPending}
        onChange={onChange}
      />
    </li>
  );
}

interface CompanionSettingsProps {
  readonly childId: string;
  readonly settings: readonly CompanionSetting[];
  readonly devices: LinkedDevices;
}

function isKnownSetting(settingId: string): settingId is (typeof SETTING_IDS)[number] {
  return (SETTING_IDS as readonly string[]).includes(settingId);
}

export function CompanionSettings({ childId, settings, devices }: CompanionSettingsProps) {
  const [enabledById, setEnabledById] = useState<EnabledById>(() =>
    Object.fromEntries(settings.map((setting) => [setting.id, setting.isEnabled])),
  );
  const [pendingId, setPendingId] = useState<string | null>(null);
  const [errorMessage, setErrorMessage] = useState<string | null>(null);

  const handleChange = async (settingId: string, isEnabled: boolean) => {
    if (!isKnownSetting(settingId)) return;
    const previous = enabledById[settingId];
    setErrorMessage(null);
    setPendingId(settingId);
    setEnabledById((current) => ({ ...current, [settingId]: isEnabled }));
    try {
      const result = await setCompanionSettingAction({ childId, settingId, isEnabled });
      if (result.ok) return;
      setErrorMessage(result.error.message);
    } catch {
      setErrorMessage(DEFAULT_ERROR_MESSAGES.INTERNAL);
    } finally {
      setPendingId(null);
    }
    setEnabledById((current) => ({ ...current, [settingId]: previous ?? !isEnabled }));
  };

  return (
    <SectionPanel icon="tune" iconTone="muted" title="Cài đặt đồng hành & Giới hạn">
      <ul className="flex flex-col gap-space-md">
        {settings.map((setting) => (
          <SettingRow
            key={setting.id}
            setting={setting}
            isEnabled={enabledById[setting.id] ?? setting.isEnabled}
            isPending={pendingId === setting.id}
            onChange={(isEnabled) => void handleChange(setting.id, isEnabled)}
          />
        ))}
        <li className="flex items-center justify-between gap-space-sm rounded-lg bg-surface-container-low p-space-sm">
          <span className="flex items-center gap-2 font-body-sm text-body-sm text-on-surface">
            <Icon name="devices" className="text-[18px] text-on-surface-variant" />
            {devices.label}
          </span>
          <DisabledNavItem
            label={devices.actionLabel}
            hasAriaLabel
            className="rounded font-label-sm text-label-sm text-primary"
          >
            {devices.actionLabel}
          </DisabledNavItem>
        </li>
      </ul>
      {errorMessage ? (
        <p role="alert" className="font-body-sm text-body-sm text-error">
          {errorMessage}
        </p>
      ) : null}
    </SectionPanel>
  );
}
