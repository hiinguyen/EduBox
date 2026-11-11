import type { DerivativeGraphFigure } from "@/lib/thi-truc-tuyen/types";
import { PromptText } from "./prompt-text";

interface DerivativeGraphProps {
  readonly figure: DerivativeGraphFigure;
}

const CURVE_PATH =
  "M 60 160 C 80 140 90 100 100 100 C 115 100 130 50 150 50 C 170 50 185 100 200 100 C 215 100 230 140 240 135 C 245 130 248 115 250 100 C 255 70 270 40 280 30";

const AXIS_LABEL_PROPS = { fill: "#737686", fontFamily: "Inter" } as const;

function GraphSvg() {
  return (
    <svg
      role="img"
      aria-label="Đồ thị đạo hàm f'(x) cắt trục hoành tại x = -1, x = 1 và x = 3, cực đại tại (0; 2)"
      className="h-48 w-72 max-w-full"
      fill="none"
      viewBox="0 0 300 200"
    >
      <line stroke="#CBD5E1" strokeWidth="1.5" x1="20" x2="280" y1="100" y2="100" />
      <line stroke="#CBD5E1" strokeWidth="1.5" x1="150" x2="150" y1="20" y2="180" />
      <path d="M280 100L272 96V104L280 100Z" fill="#737686" />
      <path d="M150 20L146 28H154L150 20Z" fill="#737686" />
      <text {...AXIS_LABEL_PROPS} fontSize="12" x="285" y="105">
        x
      </text>
      <text {...AXIS_LABEL_PROPS} fontSize="12" x="145" y="15">
        y
      </text>
      <text {...AXIS_LABEL_PROPS} fontSize="11" x="138" y="115">
        O
      </text>
      {[
        { x: 100, label: "-1", labelX: 94 },
        { x: 200, label: "1", labelX: 196 },
        { x: 250, label: "3", labelX: 246 },
      ].map((tick) => (
        <g key={tick.label}>
          <line stroke="#737686" strokeWidth="1.5" x1={tick.x} x2={tick.x} y1="97" y2="103" />
          <text {...AXIS_LABEL_PROPS} fontSize="11" x={tick.labelX} y="116">
            {tick.label}
          </text>
        </g>
      ))}
      <path d={CURVE_PATH} stroke="#004AC6" strokeLinecap="round" strokeWidth="3" />
      <circle cx="100" cy="100" fill="#BA1A1A" r="4" />
      <circle cx="200" cy="100" fill="#BA1A1A" r="4" />
      <circle cx="250" cy="100" fill="#BA1A1A" r="4" />
      <circle cx="150" cy="50" fill="#004AC6" r="3" />
      <text fill="#004AC6" fontFamily="Inter" fontSize="10" fontWeight="600" x="155" y="48">
        (0; 2)
      </text>
    </svg>
  );
}

export function DerivativeGraph({ figure }: DerivativeGraphProps) {
  return (
    <figure className="flex w-full flex-col items-center justify-around gap-space-md rounded-xl bg-surface-container-low p-space-md sm:flex-row">
      <div className="flex flex-col items-center">
        <figcaption className="mb-2 font-label-sm text-label-sm text-on-surface-variant">
          {figure.title}
        </figcaption>
        <GraphSvg />
      </div>
      <div className="flex flex-col gap-1 rounded-lg bg-surface-container-lowest p-space-md font-label-md text-label-md text-on-surface-variant shadow-sm">
        <span className="font-bold text-on-surface">{figure.notesTitle}</span>
        {figure.notes.map((segments) => (
          <p key={segments.map((segment) => segment.text).join("")}>
            <PromptText segments={segments} />
          </p>
        ))}
      </div>
    </figure>
  );
}
