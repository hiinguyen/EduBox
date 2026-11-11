export const TONES = [
  "primary",
  "secondary",
  "tertiary",
  "success",
  "error",
  "neutral",
  "muted",
] as const;

/**
 * Superset of the tones used across screens. `success` aliases the tertiary
 * (green) palette under the name the parent portal tags used. `error` is the
 * danger palette for "needs attention" bars and overdue badges.
 */
export type Tone = (typeof TONES)[number];

export const TONE_TEXT_CLASS: Readonly<Record<Tone, string>> = {
  primary: "text-primary",
  secondary: "text-secondary",
  tertiary: "text-tertiary",
  success: "text-tertiary",
  error: "text-error",
  neutral: "text-on-surface",
  muted: "text-on-surface-variant",
};

export const TONE_BG_CLASS: Readonly<Record<Tone, string>> = {
  primary: "bg-primary-fixed text-on-primary-fixed",
  secondary: "bg-secondary-fixed text-on-secondary-fixed",
  tertiary: "bg-tertiary-fixed text-on-tertiary-fixed",
  success: "bg-tertiary-fixed text-on-tertiary-fixed",
  error: "bg-error-container text-on-error-container",
  neutral: "bg-surface-container text-on-surface",
  muted: "bg-surface-container-low text-on-surface-variant",
};

export const TONE_BAR_CLASS: Readonly<Record<Tone, string>> = {
  primary: "bg-primary",
  secondary: "bg-secondary",
  tertiary: "bg-tertiary-container",
  success: "bg-tertiary-container",
  error: "bg-error",
  neutral: "bg-outline",
  muted: "bg-outline-variant",
};

export const TONE_RING_CLASS: Readonly<Record<Tone, string>> = {
  primary: "ring-primary",
  secondary: "ring-secondary",
  tertiary: "ring-tertiary",
  success: "ring-tertiary",
  error: "ring-error",
  neutral: "ring-outline",
  muted: "ring-outline-variant",
};
