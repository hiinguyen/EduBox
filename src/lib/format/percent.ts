export const MIN_PERCENT = 0;
export const MAX_PERCENT = 100;

export function clampPercent(value: number): number {
  if (!Number.isFinite(value)) return MIN_PERCENT;
  return Math.min(MAX_PERCENT, Math.max(MIN_PERCENT, value));
}
