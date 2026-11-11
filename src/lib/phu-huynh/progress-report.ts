import { roundTo } from "@/lib/format/number";
import type { Subject } from "@/generated/prisma/enums";
import { CHART_WEEKS } from "./constants";
import type { ProgressReport, ScoreSeries, SeriesTone } from "./types";

/** Subjects the chart draws, in legend order. The chart has three line styles. */
export const CHART_SUBJECTS: readonly Subject[] = ["MATH", "PHYSICS", "ENGLISH"];

const SUBJECT_STYLE: Readonly<
  Partial<Record<Subject, { readonly label: string; readonly tone: SeriesTone }>>
> = {
  MATH: { label: "Toán", tone: "primary" },
  PHYSICS: { label: "Vật lý", tone: "secondary" },
  ENGLISH: { label: "Tiếng Anh", tone: "tertiary" },
};

export interface WeekScoreRow {
  readonly subject: Subject;
  readonly weekStart: Date;
  readonly score: number;
}

const SCORE_DECIMALS = 1;

function distinctWeeks(rows: readonly WeekScoreRow[]): readonly number[] {
  const weeks = new Set(rows.map((row) => row.weekStart.getTime()));
  return [...weeks].sort((a, b) => a - b).slice(-CHART_WEEKS);
}

function buildSeries(rows: readonly WeekScoreRow[], weeks: readonly number[]): ScoreSeries[] {
  const series: ScoreSeries[] = [];
  for (const subject of CHART_SUBJECTS) {
    const style = SUBJECT_STYLE[subject];
    const byWeek = new Map(
      rows
        .filter((row) => row.subject === subject)
        .map((row) => [row.weekStart.getTime(), row.score]),
    );
    const scores = weeks.flatMap((week) => byWeek.get(week) ?? []);
    // A line with a missing week would need an invented value, so it is left out.
    if (!style || scores.length !== weeks.length) continue;
    series.push({
      id: subject.toLowerCase(),
      label: style.label,
      tone: style.tone,
      scores,
    });
  }
  return series;
}

function buildWeekLabels(count: number): readonly string[] {
  return Array.from({ length: count }, (_, index) =>
    index === count - 1 ? `Tuần ${index + 1} (Hiện tại)` : `Tuần ${index + 1}`,
  );
}

function gainOf(series: ScoreSeries): number {
  const first = series.scores[0] ?? 0;
  const last = series.scores[series.scores.length - 1] ?? 0;
  return roundTo(last - first, SCORE_DECIMALS);
}

function buildInsight(
  series: readonly ScoreSeries[],
  best: ScoreSeries,
  givenName: string,
): ProgressReport["insight"] {
  const gain = gainOf(best);
  const lead = "Nhận xét tự động:";
  if (gain <= 0 || series.length === 0) {
    return { lead, body: `Điểm các môn của ${givenName} đang giữ ổn định so với đầu kỳ.` };
  }
  return {
    lead,
    body: `Môn ${best.label} của ${givenName} tăng mạnh nhất (+${gain} điểm so với đầu kỳ).`,
  };
}

/** Builds the 6-week chart from SubjectWeekScore rows, or null when there is nothing to draw. */
export function buildProgressReport(
  rows: readonly WeekScoreRow[],
  givenName: string,
): ProgressReport | null {
  const weeks = distinctWeeks(rows);
  if (weeks.length === 0) return null;
  const series = buildSeries(rows, weeks);
  const best = series.reduce<ScoreSeries | undefined>(
    (top, candidate) => (top && gainOf(top) >= gainOf(candidate) ? top : candidate),
    undefined,
  );
  if (!best) return null;

  return {
    subtitle: `Theo dõi quỹ đạo điểm kiểm tra qua ${weeks.length} tuần gần nhất`,
    weekLabels: buildWeekLabels(weeks.length),
    series,
    highlightedSeriesId: best.id,
    insight: buildInsight(series, best, givenName),
  };
}
