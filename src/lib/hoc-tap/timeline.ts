import { MAX_PERCENT, clampPercent } from "../format/percent";

export function percentOf(value: number, total: number): number {
  if (total <= 0) return 0;
  return clampPercent((value / total) * MAX_PERCENT);
}

export function ringDashOffset(percent: number, circumference: number): number {
  return circumference * (1 - clampPercent(percent) / MAX_PERCENT);
}
