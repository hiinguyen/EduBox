import { Skeleton } from "@/components/ui/skeleton";

const STAT_PLACEHOLDER_COUNT = 4;

export default function Loading() {
  return (
    <div role="status" aria-label="Đang tải" className="flex w-full flex-col gap-space-lg">
      <Skeleton className="h-28" />
      <div className="grid grid-cols-1 gap-space-md sm:grid-cols-2 lg:grid-cols-4">
        {Array.from({ length: STAT_PLACEHOLDER_COUNT }, (_, index) => (
          <Skeleton key={index} className="h-40" />
        ))}
      </div>
      <Skeleton className="h-96" />
    </div>
  );
}
