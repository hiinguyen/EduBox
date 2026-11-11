import { Skeleton } from "@/components/ui/skeleton";

export function ExamSkeleton() {
  return (
    <div role="status" aria-live="polite" className="flex w-full flex-col gap-space-lg">
      <span className="sr-only">Đang tải bài thi</span>
      <Skeleton className="h-40 rounded-xl" />
      <div className="grid grid-cols-1 gap-space-lg lg:grid-cols-12">
        <Skeleton className="h-96 rounded-xl lg:col-span-4 xl:col-span-3" />
        <Skeleton className="h-[32rem] rounded-xl lg:col-span-8 xl:col-span-9" />
      </div>
    </div>
  );
}
