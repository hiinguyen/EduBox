import { Icon } from "@/components/ui/icon";
import { Pill } from "@/components/ui/pill";
import { ProgressBar } from "@/components/ui/progress-bar";
import { SectionPanel } from "@/components/ui/section-panel";
import type { KnowledgeGap, KnowledgeGapTone, KnowledgeInsights } from "@/lib/giao-vien/types";
import { TONE_BAR_CLASS, TONE_TEXT_CLASS, type Tone } from "@/lib/ui/tone";
import { ComingSoonButton } from "./coming-soon-button";

const GAP_TONE: Readonly<Record<KnowledgeGapTone, Tone>> = {
  mastered: "tertiary",
  confused: "secondary",
};

const GAP_LABEL: Readonly<Record<KnowledgeGapTone, string>> = {
  mastered: "nắm vững",
  confused: "còn nhầm lẫn",
};

function GapRow({ gap }: { readonly gap: KnowledgeGap }) {
  const tone = GAP_TONE[gap.tone];
  return (
    <li className="space-y-1">
      <div className="flex justify-between gap-space-sm font-label-md text-label-md text-on-surface">
        <span className="flex items-center gap-1.5 font-medium">
          <span
            aria-hidden="true"
            className={`h-2 w-2 shrink-0 rounded-full ${TONE_BAR_CLASS[tone]}`}
          />
          {gap.topic}
        </span>
        <span className={`shrink-0 font-bold ${TONE_TEXT_CLASS[tone]}`}>
          {gap.percent}% {GAP_LABEL[gap.tone]}
        </span>
      </div>
      <ProgressBar value={gap.percent} label={gap.topic} tone={tone} />
      <p className="text-xs text-on-surface-variant">{gap.note}</p>
    </li>
  );
}

export function KnowledgeInsightsCard({ insights }: { readonly insights: KnowledgeInsights }) {
  const { remediation } = insights;
  return (
    <SectionPanel
      title="Phân tích lỗ hổng kiến thức của lớp (AI Insights)"
      icon="analytics"
      iconTone="secondary"
      aside={<Pill tone="secondary">AI quét {insights.scannedSubmissions} bài nộp</Pill>}
    >
      <ul className="space-y-space-md">
        {insights.gaps.map((gap) => (
          <GapRow key={gap.id} gap={gap} />
        ))}
      </ul>
      <div className="mt-space-xs flex items-start gap-space-sm rounded-lg bg-surface-container-low p-space-md">
        <Icon name="tips_and_updates" className="mt-0.5 shrink-0 text-[22px] text-secondary" />
        <div className="flex-1">
          <div className="font-label-md text-label-md font-semibold text-on-surface">
            Gợi ý bài giảng bổ trợ cần bổ sung:
          </div>
          <p className="mt-0.5 font-body-sm text-body-sm text-on-surface-variant">
            {remediation.intro}{" "}
            <span className="font-medium text-primary">&quot;{remediation.lectureTitle}&quot;</span>{" "}
            {remediation.outro}
          </p>
          <div className="mt-space-sm flex flex-wrap gap-space-xs">
            <ComingSoonButton className="rounded-lg bg-secondary px-space-md py-1.5 font-label-sm text-label-sm text-on-secondary">
              Tạo bài tập bổ trợ tự động
            </ComingSoonButton>
            <ComingSoonButton className="rounded-lg bg-surface-container-high px-space-md py-1.5 font-label-sm text-label-sm text-on-surface">
              Gửi cảnh báo đến nhóm yếu
            </ComingSoonButton>
          </div>
        </div>
      </div>
    </SectionPanel>
  );
}
