export interface ChartPoint {
  readonly x: number;
  readonly y: number;
}

export interface ScoreGridLine {
  readonly score: number;
  readonly y: number;
}

export const CHART_VIEWBOX = { width: 640, height: 220 } as const;
export const SCORE_MIN = 4;
export const SCORE_MAX = 10;
export const SCORE_GRID_STEP = 2;
export const PLOT_LEFT_X = 60;
export const PLOT_RIGHT_X = 600;
export const PLOT_TOP_Y = 30;
export const PLOT_BOTTOM_Y = 165;

const COORDINATE_DECIMALS = 2;

function formatCoordinate(value: number): string {
  return Number(value.toFixed(COORDINATE_DECIMALS)).toString();
}

export function scoreToY(score: number): number {
  const clamped = Math.min(SCORE_MAX, Math.max(SCORE_MIN, score));
  const ratio = (SCORE_MAX - clamped) / (SCORE_MAX - SCORE_MIN);
  return PLOT_TOP_Y + ratio * (PLOT_BOTTOM_Y - PLOT_TOP_Y);
}

export function indexToX(index: number, count: number): number {
  if (count < 2) return PLOT_LEFT_X;
  return PLOT_LEFT_X + (index * (PLOT_RIGHT_X - PLOT_LEFT_X)) / (count - 1);
}

export function buildPoints(scores: readonly number[]): readonly ChartPoint[] {
  return scores.map((score, index) => ({
    x: indexToX(index, scores.length),
    y: scoreToY(score),
  }));
}

export function toPointsAttribute(points: readonly ChartPoint[]): string {
  return points.map((p) => `${formatCoordinate(p.x)},${formatCoordinate(p.y)}`).join(" ");
}

export function toAreaPath(points: readonly ChartPoint[]): string {
  const first = points[0];
  const last = points[points.length - 1];
  if (!first || !last) return "";
  const line = points.map(
    (p, i) => `${i === 0 ? "M" : "L"}${formatCoordinate(p.x)},${formatCoordinate(p.y)}`,
  );
  return [
    ...line,
    `L${formatCoordinate(last.x)},${PLOT_BOTTOM_Y}`,
    `L${formatCoordinate(first.x)},${PLOT_BOTTOM_Y}`,
    "Z",
  ].join(" ");
}

export function buildGridLines(): readonly ScoreGridLine[] {
  const lines: ScoreGridLine[] = [];
  for (let score = SCORE_MAX; score >= SCORE_MIN; score -= SCORE_GRID_STEP) {
    lines.push({ score, y: scoreToY(score) });
  }
  return lines;
}
