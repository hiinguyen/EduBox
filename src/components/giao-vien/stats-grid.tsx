import type { ReactNode } from "react";
import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import type { TeacherStats } from "@/lib/giao-vien/types";

interface StatCardProps {
  readonly label: string;
  readonly iconName: string;
  readonly iconClassName: string;
  readonly className?: string;
  readonly children: ReactNode;
}

function StatCard({ label, iconName, iconClassName, className = "", children }: StatCardProps) {
  return (
    <Card className={`flex flex-col justify-between ${className}`}>
      <div className="flex items-center justify-between gap-space-sm">
        <span className="font-label-sm text-label-sm uppercase tracking-wider text-outline">
          {label}
        </span>
        <div
          className={`flex h-10 w-10 shrink-0 items-center justify-center rounded-lg ${iconClassName}`}
        >
          <Icon name={iconName} className="text-[22px]" />
        </div>
      </div>
      <div className="mt-space-md">{children}</div>
    </Card>
  );
}

const BIG_NUMBER_CLASS = "font-headline-lg text-headline-lg leading-none";
const NOTE_CLASS = "mt-space-xs font-body-sm text-body-sm";
const NO_DATA = "--";
const AVERAGE_DECIMALS = 2;

function PendingNote({
  pending,
  deadline,
}: {
  readonly pending: number;
  readonly deadline: string | null;
}) {
  if (pending === 0 || deadline === null) {
    return (
      <p className={`${NOTE_CLASS} text-on-surface-variant`}>
        {pending === 0 ? "Đã chấm xong mọi bài nộp" : "Chưa đặt hạn chấm bài"}
      </p>
    );
  }
  return (
    <p className={`${NOTE_CLASS} flex items-center gap-1 font-medium text-error`}>
      <Icon name="schedule" className="text-[16px]" /> Cần hoàn thành trước {deadline}
    </p>
  );
}

export function StatsGrid({ stats }: { readonly stats: TeacherStats }) {
  return (
    <section
      aria-label="Chỉ số tổng quan"
      className="grid grid-cols-1 gap-space-md sm:grid-cols-2 xl:grid-cols-4"
    >
      <StatCard
        label="Tổng số học sinh"
        iconName="groups"
        iconClassName="bg-primary-fixed text-primary"
      >
        <div className={`${BIG_NUMBER_CLASS} text-on-surface`}>{stats.totalStudents}</div>
        <p className={`${NOTE_CLASS} text-on-surface-variant`}>
          Phân bổ tại {stats.classNames.length} lớp: {stats.classNames.join(", ")}
        </p>
      </StatCard>
      <StatCard
        label="Bài tập cần chấm"
        iconName="pending_actions"
        iconClassName="bg-error-container text-error"
        className="relative overflow-hidden"
      >
        <div className="pointer-events-none absolute -right-3 -top-3 h-16 w-16 rounded-full bg-error-container/30 blur-xl" />
        <div className="flex items-baseline gap-space-xs">
          <span className={`${BIG_NUMBER_CLASS} text-error`}>{stats.pendingSubmissions}</span>
          <span className="font-label-md text-label-md text-on-surface-variant">bài nộp mới</span>
        </div>
        <PendingNote pending={stats.pendingSubmissions} deadline={stats.gradingDeadlineLabel} />
      </StatCard>
      <StatCard
        label="Tỷ lệ hoàn thành"
        iconName="verified"
        iconClassName="bg-tertiary-fixed text-tertiary"
      >
        <div className={`${BIG_NUMBER_CLASS} text-on-surface`}>
          {stats.completion ? `${stats.completion.percent}%` : NO_DATA}
        </div>
        <p className={`${NOTE_CLASS} text-on-surface-variant`}>
          {stats.completion
            ? `${stats.completion.submitted}/${stats.completion.expected} bài nộp trên số bài được giao`
            : "Chưa có bài kiểm tra được giao"}
        </p>
      </StatCard>
      <StatCard
        label="Điểm trung bình đợt thi"
        iconName="insights"
        iconClassName="bg-secondary-fixed text-secondary"
      >
        <div className="flex items-baseline gap-space-xs">
          <span className={`${BIG_NUMBER_CLASS} text-on-surface`}>
            {stats.average ? stats.average.score.toFixed(AVERAGE_DECIMALS) : NO_DATA}
          </span>
          <span className="font-body-sm text-body-sm text-on-surface-variant">/ 10</span>
        </div>
        <p className={`${NOTE_CLASS} text-on-surface-variant`}>
          {stats.average?.sourceTitle ?? "Chưa có bài nào được chấm"}
        </p>
      </StatCard>
    </section>
  );
}
