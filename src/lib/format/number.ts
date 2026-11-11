/** Rounds to `decimals` places, half away from zero, without floating-point drift (1.005 -> 1.01). */
export function roundTo(value: number, decimals: number): number {
  if (!Number.isFinite(value)) {
    return value;
  }
  const rounded = Number(`${Math.round(Number(`${Math.abs(value)}e${decimals}`))}e-${decimals}`);
  return value < 0 ? -rounded : rounded;
}
