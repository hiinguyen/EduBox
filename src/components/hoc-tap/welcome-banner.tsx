import { Icon } from "@/components/ui/icon";
import { Card } from "@/components/ui/card";
import { Pill } from "@/components/ui/pill";
import type { WeeklySummary } from "@/lib/hoc-tap/types";
import { WeeklyCallout } from "./weekly-callout";

interface WelcomeBannerProps {
  readonly summary: WeeklySummary;
}

export function WelcomeBanner({ summary }: WelcomeBannerProps) {
  return (
    <Card as="section" aria-labelledby="hoc-tap-heading" className="relative overflow-hidden">
      <div
        aria-hidden="true"
        className="pointer-events-none absolute -right-16 -top-16 h-80 w-80 rounded-full bg-gradient-to-br from-primary-fixed/30 to-secondary-fixed/30 blur-3xl"
      />
      <div className="relative z-10 flex flex-col gap-space-lg xl:flex-row xl:items-center xl:justify-between">
        <div className="max-w-2xl">
          <div className="mb-space-xs flex flex-wrap items-center gap-space-sm">
            <Pill tone="primary">
              <Icon name="verified" filled className="text-[16px] text-primary" />
              {summary.weekLabel}
            </Pill>
            <span aria-hidden="true" className="font-label-sm text-label-sm text-outline">
              •
            </span>
            <span className="flex items-center gap-1 font-label-sm text-label-sm font-semibold text-tertiary">
              <span
                aria-hidden="true"
                className="h-2 w-2 animate-ping rounded-full bg-tertiary-container motion-reduce:animate-none"
              />
              Kỷ luật {summary.streakDays} ngày liên tiếp
            </span>
          </div>
          <h1
            id="hoc-tap-heading"
            className="font-headline-lg text-headline-lg-mobile text-on-surface tracking-tight md:text-headline-lg"
          >
            Chào {summary.studentFirstName}, hôm nay bạn muốn chinh phục môn học nào?
          </h1>
          <p className="mt-1 font-body-md text-body-md text-on-surface-variant">
            Hệ thống đã chuẩn bị sẵn sơ đồ tư duy Toán giải tích và lộ trình ôn luyện tối ưu cho
            buổi chiều nay.
          </p>
        </div>

        <WeeklyCallout summary={summary} />
      </div>
    </Card>
  );
}
