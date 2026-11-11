import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import { Pill } from "@/components/ui/pill";
import type { Lecture, LectureLibraryData } from "@/lib/giao-vien/types";
import { ComingSoonButton } from "./coming-soon-button";
import { PaginationNav } from "./pagination-nav";

interface LectureLibraryProps {
  readonly library: LectureLibraryData;
  readonly hrefForPage: (page: number) => string;
}

const UNASSIGNED_LABEL = "Chưa gán";
const HEAD_CELL = "p-space-md font-label-sm text-label-sm";

function getClassLabel(lecture: Lecture): string {
  return lecture.classNames.length > 0 ? lecture.classNames.join(", ") : UNASSIGNED_LABEL;
}

function StatusBadge({ status }: { readonly status: Lecture["status"] }) {
  const isPublished = status === "published";
  return (
    <Pill tone={isPublished ? "success" : "neutral"} className="whitespace-nowrap">
      <span
        aria-hidden="true"
        className={`h-1.5 w-1.5 rounded-full ${isPublished ? "bg-tertiary" : "bg-outline"}`}
      />
      {isPublished ? "Đã xuất bản" : "Bản nháp"}
    </Pill>
  );
}

function LectureRow({ lecture }: { readonly lecture: Lecture }) {
  const hasViews = lecture.viewCount > 0;
  return (
    <tr className="transition-colors hover:bg-surface-container-low">
      <th scope="row" className="min-w-72 p-space-md text-left font-normal">
        <div className="flex items-center gap-space-md">
          <div
            aria-hidden="true"
            className="flex h-10 w-16 shrink-0 items-center justify-center rounded-lg bg-surface-container-high text-primary shadow-sm"
          >
            <Icon name="play_circle" filled className="text-[24px]" />
          </div>
          <div className="flex min-w-0 flex-col">
            <span className="font-label-md text-label-md text-on-surface">{lecture.title}</span>
            <span className="font-body-sm text-body-sm text-on-surface-variant">
              {lecture.subtitle}
            </span>
          </div>
        </div>
      </th>
      <td className="whitespace-nowrap p-space-md font-medium text-on-surface">
        {lecture.durationLabel}
      </td>
      <td className="p-space-md">
        <Pill tone="neutral" className="whitespace-nowrap">
          {getClassLabel(lecture)}
        </Pill>
      </td>
      <td className="p-space-md">
        <div
          className={`flex items-center gap-1 ${hasViews ? "text-on-surface" : "text-on-surface-variant"}`}
        >
          <Icon name={hasViews ? "visibility" : "visibility_off"} className="text-[18px]" />
          <span>{lecture.viewCount}</span>
        </div>
      </td>
      <td className="whitespace-nowrap p-space-md">
        {lecture.rating ? (
          <div className="flex items-center gap-1 text-on-surface">
            <Icon name="star" filled className="text-[16px] text-secondary" />
            <span className="font-semibold">{lecture.rating.average.toFixed(1)}</span>
            <span className="text-xs text-on-surface-variant">({lecture.rating.count})</span>
          </div>
        ) : (
          <span className="text-xs text-on-surface-variant">Chưa có</span>
        )}
      </td>
      <td className="p-space-md">
        <StatusBadge status={lecture.status} />
      </td>
      <td className="sticky right-0 bg-surface-container-lowest p-space-md text-right">
        <ComingSoonButton className="rounded-lg p-2 text-primary">
          <Icon name="edit" className="text-[20px]" />
          <span className="sr-only">Chỉnh sửa bài giảng: {lecture.title}</span>
        </ComingSoonButton>
      </td>
    </tr>
  );
}

export function LectureLibrary({ library, hrefForPage }: LectureLibraryProps) {
  return (
    <Card
      as="section"
      aria-labelledby="lecture-library-title"
      className="flex flex-col gap-space-md"
    >
      <div className="flex flex-col justify-between gap-space-sm sm:flex-row sm:items-center">
        <div className="flex items-center gap-space-sm">
          <Icon name="folder_special" className="text-[24px] text-primary" />
          <div>
            <h2
              id="lecture-library-title"
              className="font-headline-sm text-headline-sm text-on-surface"
            >
              Quản lý Bài giảng Video &amp; Ngân hàng đề thi
            </h2>
            <p className="font-body-sm text-body-sm text-on-surface-variant">
              Hệ thống bài giảng chuyên đề đã quay dựng và liên kết với lớp trực tuyến
            </p>
          </div>
        </div>
        <div className="flex items-center gap-space-xs">
          <Pill tone="neutral" className="whitespace-nowrap">
            Tổng: {library.total} bài giảng
          </Pill>
          <Pill tone="success" className="whitespace-nowrap">
            {library.approved} đã duyệt
          </Pill>
        </div>
      </div>
      <div className="overflow-x-auto">
        <table className="w-full min-w-[44rem] text-left font-body-sm text-body-sm">
          <caption className="sr-only">Danh sách bài giảng video của giáo viên</caption>
          <thead>
            <tr className="bg-surface-container-low text-on-surface-variant">
              <th scope="col" className={`${HEAD_CELL} rounded-l-lg`}>
                Tên bài giảng
              </th>
              <th scope="col" className={HEAD_CELL}>
                Thời lượng
              </th>
              <th scope="col" className={HEAD_CELL}>
                Lớp áp dụng
              </th>
              <th scope="col" className={HEAD_CELL}>
                Lượt xem
              </th>
              <th scope="col" className={HEAD_CELL}>
                Đánh giá
              </th>
              <th scope="col" className={HEAD_CELL}>
                Trạng thái
              </th>
              <th
                scope="col"
                className={`${HEAD_CELL} sticky right-0 rounded-r-lg bg-surface-container-low text-right`}
              >
                Thao tác
              </th>
            </tr>
          </thead>
          <tbody>
            {library.items.map((lecture) => (
              <LectureRow key={lecture.id} lecture={lecture} />
            ))}
          </tbody>
        </table>
      </div>
      <PaginationNav
        label="Phân trang bài giảng"
        pagination={library.pagination}
        hrefForPage={hrefForPage}
      />
    </Card>
  );
}
