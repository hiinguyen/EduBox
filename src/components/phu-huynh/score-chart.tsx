import { useId } from "react";
import {
  buildGridLines,
  buildPoints,
  CHART_VIEWBOX,
  indexToX,
  PLOT_LEFT_X,
  PLOT_RIGHT_X,
  toAreaPath,
  toPointsAttribute,
} from "@/lib/phu-huynh/chart";
import type { ChartPoint } from "@/lib/phu-huynh/chart";
import type { ProgressReport, ScoreSeries, SeriesTone } from "@/lib/phu-huynh/types";

interface ToneStyle {
  readonly stroke: string;
  readonly fill: string;
  readonly cssVar: string;
  readonly strokeWidth: number;
  readonly dashArray?: string;
  readonly dotRadius: number;
}

const TONE_STYLE: Readonly<Record<SeriesTone, ToneStyle>> = {
  primary: {
    stroke: "stroke-primary",
    fill: "fill-primary",
    cssVar: "var(--color-primary)",
    strokeWidth: 3,
    dotRadius: 5,
  },
  secondary: {
    stroke: "stroke-secondary",
    fill: "fill-secondary",
    cssVar: "var(--color-secondary)",
    strokeWidth: 2.5,
    dotRadius: 4.5,
  },
  tertiary: {
    stroke: "stroke-tertiary",
    fill: "fill-tertiary",
    cssVar: "var(--color-tertiary)",
    strokeWidth: 2,
    dashArray: "4,3",
    dotRadius: 4,
  },
};

const GRID_OVERHANG = 20;
const GRID_LABEL_X = 28;
const GRID_LABEL_BASELINE_OFFSET = 4;
const GRID_LINE_OPACITY = 0.4;
const AXIS_LABEL_Y = 195;
const AREA_START_OPACITY = 0.25;
const CALLOUT = { width: 65, height: 24, top: 20, radius: 6 } as const;
const CALLOUT_TEXT_BASELINE = 16;

function lastOf<T>(items: readonly T[]): T | undefined {
  return items[items.length - 1];
}

function Grid() {
  return (
    <>
      {buildGridLines().map((line) => (
        <g key={line.score}>
          <line
            x1={PLOT_LEFT_X - GRID_OVERHANG}
            x2={PLOT_RIGHT_X + GRID_OVERHANG}
            y1={line.y}
            y2={line.y}
            strokeDasharray="3,3"
            className="stroke-outline-variant"
            opacity={GRID_LINE_OPACITY}
          />
          <text
            x={GRID_LABEL_X}
            y={line.y + GRID_LABEL_BASELINE_OFFSET}
            textAnchor="end"
            fontSize={11}
            className="fill-on-surface-variant"
          >
            {line.score}
          </text>
        </g>
      ))}
    </>
  );
}

function WeekAxis({ labels }: { readonly labels: readonly string[] }) {
  return (
    <>
      {labels.map((label, index) => (
        <text
          key={label}
          x={indexToX(index, labels.length)}
          y={AXIS_LABEL_Y}
          textAnchor="middle"
          fontSize={12}
          className="fill-on-surface-variant"
        >
          {label}
        </text>
      ))}
    </>
  );
}

function SeriesLine({ series }: { readonly series: ScoreSeries }) {
  const style = TONE_STYLE[series.tone];
  const points = buildPoints(series.scores);
  const end = lastOf(points);
  return (
    <g>
      <polyline
        fill="none"
        points={toPointsAttribute(points)}
        strokeWidth={style.strokeWidth}
        strokeDasharray={style.dashArray}
        strokeLinecap="round"
        strokeLinejoin="round"
        className={style.stroke}
      />
      {end ? (
        <circle
          cx={end.x}
          cy={end.y}
          r={style.dotRadius}
          strokeWidth={2}
          className={`${style.fill} stroke-surface-container-lowest`}
        />
      ) : null}
    </g>
  );
}

interface CalloutProps {
  readonly point: ChartPoint;
  readonly text: string;
}

function Callout({ point, text }: CalloutProps) {
  return (
    <g transform={`translate(${point.x - CALLOUT.width / 2}, ${CALLOUT.top})`}>
      <rect
        width={CALLOUT.width}
        height={CALLOUT.height}
        rx={CALLOUT.radius}
        className="fill-primary"
      />
      <text
        x={CALLOUT.width / 2}
        y={CALLOUT_TEXT_BASELINE}
        textAnchor="middle"
        fontSize={11}
        fontWeight={600}
        className="fill-on-primary"
      >
        {text}
      </text>
    </g>
  );
}

function buildSummary(series: readonly ScoreSeries[]): string {
  return series.map((s) => `${s.label} ${lastOf(s.scores)?.toFixed(1)}`).join(", ");
}

interface ScoreChartProps {
  readonly progress: ProgressReport;
}

export function ScoreChart({ progress }: ScoreChartProps) {
  const gradientId = useId();
  const highlighted = progress.series.find((s) => s.id === progress.highlightedSeriesId);
  const highlightedPoints = highlighted ? buildPoints(highlighted.scores) : [];
  const lastPoint = lastOf(highlightedPoints);
  const lastScore = highlighted ? lastOf(highlighted.scores) : undefined;
  const gradientColor = highlighted ? TONE_STYLE[highlighted.tone].cssVar : undefined;

  return (
    <div className="w-full rounded-xl bg-surface-container-low p-space-md">
      <svg
        role="img"
        aria-label={`Biểu đồ điểm ${progress.weekLabels.length} tuần gần nhất. Tuần hiện tại: ${buildSummary(progress.series)}.`}
        viewBox={`0 0 ${CHART_VIEWBOX.width} ${CHART_VIEWBOX.height}`}
        className="h-auto w-full select-none overflow-visible"
      >
        <defs>
          {gradientColor ? (
            <linearGradient id={gradientId} x1="0" x2="0" y1="0" y2="1">
              <stop
                offset="0%"
                style={{ stopColor: gradientColor }}
                stopOpacity={AREA_START_OPACITY}
              />
              <stop offset="100%" style={{ stopColor: gradientColor }} stopOpacity={0} />
            </linearGradient>
          ) : null}
        </defs>
        <Grid />
        <WeekAxis labels={progress.weekLabels} />
        {highlighted ? (
          <path d={toAreaPath(highlightedPoints)} fill={`url(#${gradientId})`} />
        ) : null}
        {progress.series.map((series) => (
          <SeriesLine key={series.id} series={series} />
        ))}
        {highlighted && lastPoint && lastScore !== undefined ? (
          <Callout point={lastPoint} text={`${highlighted.label}: ${lastScore.toFixed(1)}`} />
        ) : null}
      </svg>
    </div>
  );
}
