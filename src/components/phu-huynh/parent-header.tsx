import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import { Pill } from "@/components/ui/pill";
import type { ParentProfile } from "@/lib/phu-huynh/types";
import type { ChildOption } from "@/lib/phu-huynh/view-model";
import { ChildSwitcher } from "./child-switcher";

interface ParentHeaderProps {
  readonly parent: ParentProfile;
  readonly academicYear: string;
  readonly childOptions: readonly ChildOption[];
  readonly selectedChildId: string;
}

export function ParentHeader({
  parent,
  academicYear,
  childOptions,
  selectedChildId,
}: ParentHeaderProps) {
  return (
    <Card
      as="section"
      aria-label="Thông tin phụ huynh"
      className="flex w-full flex-col items-start justify-between gap-space-md md:flex-row md:items-center"
    >
      <div className="flex items-center gap-space-md">
        <div className="relative flex h-14 w-14 shrink-0 items-center justify-center rounded-full bg-secondary-fixed">
          <Icon name="shield_person" filled className="text-[32px] text-secondary" />
          <span className="absolute bottom-0 right-0 h-4 w-4 rounded-full bg-tertiary-container ring-2 ring-surface-container-lowest" />
        </div>
        <div>
          <div className="mb-1 flex flex-wrap items-center gap-space-xs">
            <Pill tone="secondary">Không gian Phụ huynh</Pill>
            <span className="font-label-sm text-label-sm text-outline">
              · Niên khóa {academicYear}
            </span>
          </div>
          <h1 className="font-headline-md text-headline-md text-on-surface">
            Cổng Đồng hành cùng Con
          </h1>
          <p className="font-body-sm text-body-sm text-on-surface-variant">
            Phụ huynh:{" "}
            <strong className="font-label-md text-label-md text-on-surface">
              {parent.displayName}
            </strong>
          </p>
        </div>
      </div>
      <ChildSwitcher childOptions={childOptions} selectedChildId={selectedChildId} />
    </Card>
  );
}
