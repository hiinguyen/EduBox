import { Skeleton } from "@/components/ui/skeleton";

const STAT_PLACEHOLDER_COUNT = 4;

export default function Loading() {
  return (
    <div
      role="status"
      aria-label="Đang tải không gian giáo viên"
      className="flex flex-col gap-space-lg"
    >
      <Skeleton className="h-32 rounded-xl" />
      <div className="grid grid-cols-1 gap-space-md sm:grid-cols-2 xl:grid-cols-4">
        {Array.from({ length: STAT_PLACEHOLDER_COUNT }, (_, index) => (
          <Skeleton key={index} className="h-36 rounded-xl" />
        ))}
      </div>
      <Skeleton className="h-72 rounded-xl" />
    </div>
  );
}
