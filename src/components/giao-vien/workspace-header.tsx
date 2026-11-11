import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import { Pill } from "@/components/ui/pill";
import type { Teacher } from "@/lib/giao-vien/types";
import { ComingSoonButton } from "./coming-soon-button";

interface WorkspaceHeaderProps {
  readonly teacher: Teacher;
}

const ACTION_BASE =
  "flex items-center gap-space-xs rounded-lg px-space-md py-2.5 font-label-md text-label-md shadow-sm";

export function WorkspaceHeader({ teacher }: WorkspaceHeaderProps) {
  return (
    <Card
      as="header"
      className="flex flex-col justify-between gap-space-md lg:flex-row lg:items-center"
    >
      <div className="flex flex-col gap-space-xs">
        <div className="flex flex-wrap items-center gap-space-sm">
          <Pill tone="primary">{teacher.termLabel}</Pill>
          <Pill tone="neutral">{teacher.subjectLabel}</Pill>
        </div>
        <h1 className="font-headline-md text-headline-md tracking-tight text-on-surface">
          Không gian Giảng dạy - {teacher.displayName}
        </h1>
        <p className="font-body-sm text-body-sm text-on-surface-variant">
          {teacher.department} · Quản lý kế hoạch giảng dạy, số hóa kho đề và chấm bài thông minh
        </p>
      </div>
      <div className="flex flex-wrap items-center gap-space-sm">
        <ComingSoonButton className={`${ACTION_BASE} bg-surface-container-high text-on-surface`}>
          <Icon name="table_view" className="text-[18px] text-tertiary" />
          <span>Xuất báo cáo điểm Excel</span>
        </ComingSoonButton>
        <ComingSoonButton className={`${ACTION_BASE} bg-secondary-fixed text-on-secondary-fixed`}>
          <Icon name="quiz" className="text-[18px]" />
          <span>+ Tạo Đề kiểm tra mới</span>
        </ComingSoonButton>
        <ComingSoonButton className={`${ACTION_BASE} bg-primary text-on-primary`}>
          <Icon name="video_call" className="text-[18px]" />
          <span>+ Tải lên Bài giảng Video</span>
        </ComingSoonButton>
      </div>
    </Card>
  );
}
