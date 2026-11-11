import Link from "next/link";
import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import type { ScreenHref } from "@/lib/screens";
import type { Homework } from "@/lib/hoc-tap/types";

const EXAM_HREF = "/thi-truc-tuyen" satisfies ScreenHref;

interface HomeworkCardProps {
  readonly homework: Homework | null;
}

function EmptyHomework() {
  return (
    <p className="rounded-lg bg-surface-container-low p-space-sm font-body-sm text-body-sm text-on-surface-variant">
      Bạn không có bài tập nào sắp đến hạn. Làm tốt lắm!
    </p>
  );
}

export function HomeworkCard({ homework }: HomeworkCardProps) {
  return (
    <Card
      as="section"
      aria-labelledby="homework-heading"
      className="relative flex flex-col gap-space-sm overflow-hidden p-space-md!"
    >
      <div className="flex items-center justify-between gap-space-sm">
        <div className="flex items-center gap-1.5">
          <Icon name="alarm" className="text-[20px] text-error" />
          <h2 id="homework-heading" className="font-headline-sm text-headline-sm text-on-surface">
            Bài tập cần nộp hôm nay
          </h2>
        </div>
        {homework ? (
          <span className="shrink-0 rounded-full bg-error-container px-2 py-0.5 font-label-sm text-label-sm font-semibold text-on-error-container">
            {homework.deadlineLabel}
          </span>
        ) : null}
      </div>
      {homework ? <HomeworkDetails homework={homework} /> : <EmptyHomework />}
    </Card>
  );
}

function HomeworkDetails({ homework }: { readonly homework: Homework }) {
  return (
    <div className="flex flex-col gap-2 rounded-lg bg-surface-container-low p-space-sm">
      <div>
        <h3 className="font-label-md text-label-md font-bold text-on-surface">{homework.title}</h3>
        <p className="font-label-sm text-label-sm text-on-surface-variant">{homework.details}</p>
      </div>
      <div className="flex items-center justify-between gap-space-sm pt-1">
        <div className="flex items-center gap-1 font-label-sm text-label-sm text-on-surface-variant">
          <Icon name="check_circle" className="text-[16px] text-tertiary" />
          <span>
            Đã làm: {homework.answered}/{homework.total} câu
          </span>
        </div>
        <Link
          href={EXAM_HREF}
          className="flex items-center gap-1 rounded-lg bg-primary px-4 py-1.5 font-label-md text-label-md text-on-primary shadow-sm transition-all hover:bg-primary-container"
        >
          <span>Làm bài ngay</span>
          <Icon name="arrow_forward" className="text-[16px]" />
        </Link>
      </div>
    </div>
  );
}
