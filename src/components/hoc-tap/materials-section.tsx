import Link from "next/link";
import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import { materialFilterHref } from "@/lib/hoc-tap/materials";
import type { MaterialFilter, MaterialFilterOption, StudyMaterial } from "@/lib/hoc-tap/types";
import { TONE_BG_CLASS, TONE_TEXT_CLASS } from "@/lib/ui/tone";
import { ComingSoonButton } from "./coming-soon-button";

interface MaterialsSectionProps {
  readonly activeFilter: MaterialFilter;
  readonly filters: readonly MaterialFilterOption[];
  readonly materials: readonly StudyMaterial[];
}

function MaterialItem({ material }: { readonly material: StudyMaterial }) {
  const footnoteClass = material.isRecommended
    ? "flex items-center gap-1 text-tertiary"
    : "text-on-surface-variant";
  return (
    <article className="flex flex-col justify-between gap-space-md rounded-xl bg-surface-container-low p-space-md transition-all hover:bg-surface-container">
      <div className="flex items-start gap-space-sm">
        <div
          className={`flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-lg ${TONE_BG_CLASS[material.tone]}`}
        >
          <Icon name={material.icon} className="text-[24px]" />
        </div>
        <div className="flex min-w-0 flex-col">
          <span
            className={`font-label-sm text-label-sm font-bold uppercase ${TONE_TEXT_CLASS[material.tone]}`}
          >
            {material.kind}
          </span>
          <h3
            className="truncate font-label-md text-label-md font-semibold text-on-surface"
            title={material.title}
          >
            {material.title}
          </h3>
          <span className="font-label-sm text-label-sm text-on-surface-variant">
            {material.detail}
          </span>
        </div>
      </div>
      <div className="flex items-center justify-between pt-2">
        <span className={`font-label-sm text-label-sm ${footnoteClass}`}>
          {material.isRecommended ? <Icon name="verified" className="text-[16px]" /> : null}
          {material.footnote}
        </span>
        <ComingSoonButton
          label={`Tải xuống ${material.title}`}
          className="rounded-lg bg-surface-container-lowest p-2 text-primary shadow-sm"
        >
          <Icon name="download" className="text-[18px]" />
        </ComingSoonButton>
      </div>
    </article>
  );
}

export function MaterialsSection({ activeFilter, filters, materials }: MaterialsSectionProps) {
  return (
    <Card as="section" aria-labelledby="materials-heading" className="flex flex-col gap-space-md">
      <div className="flex flex-col justify-between gap-space-md md:flex-row md:items-center">
        <div>
          <div className="flex items-center gap-space-sm">
            <span aria-hidden="true" className="h-6 w-2.5 rounded-full bg-secondary" />
            <h2
              id="materials-heading"
              className="font-headline-md text-headline-md text-on-surface"
            >
              Tài liệu học tập đề xuất
            </h2>
          </div>
          <p className="font-body-sm text-body-sm text-on-surface-variant">
            Tài liệu chuẩn hóa bám sát cấu trúc đề thi tốt nghiệp THPT và kỳ thi Đánh giá năng lực.
          </p>
        </div>
        <div
          role="group"
          aria-label="Lọc tài liệu theo môn"
          className="flex items-center gap-1.5 overflow-x-auto pb-1"
        >
          {filters.map((option) => {
            const isActive = option.value === activeFilter;
            return (
              <Link
                key={option.value}
                href={materialFilterHref(option.value)}
                scroll={false}
                aria-current={isActive ? "true" : undefined}
                className={`shrink-0 rounded-full px-3 py-1.5 font-label-sm text-label-sm transition-colors ${
                  isActive
                    ? "bg-primary text-on-primary"
                    : "bg-surface-container text-on-surface-variant hover:text-on-surface"
                }`}
              >
                {option.label}
              </Link>
            );
          })}
        </div>
      </div>
      {materials.length === 0 ? (
        <p className="rounded-xl bg-surface-container-low p-space-md text-center font-body-sm text-body-sm text-on-surface-variant">
          Chưa có tài liệu cho môn này.
        </p>
      ) : (
        <div className="grid grid-cols-1 gap-space-md pt-space-xs md:grid-cols-3">
          {materials.map((material) => (
            <MaterialItem key={material.id} material={material} />
          ))}
        </div>
      )}
    </Card>
  );
}
