import { Skeleton } from "@/components/ui/skeleton";

export default function Loading() {
  return (
    <div
      role="status"
      aria-label="Đang tải trang học tập"
      className="flex w-full flex-col gap-space-xl"
    >
      <Skeleton className="h-48 rounded-xl" />
      <div className="grid grid-cols-1 items-start gap-space-xl lg:grid-cols-12">
        <div className="flex flex-col gap-space-xl lg:col-span-8">
          <Skeleton className="aspect-video rounded-xl" />
          <Skeleton className="h-64 rounded-xl" />
        </div>
        <div className="flex flex-col gap-space-lg lg:col-span-4">
          <Skeleton className="h-96 rounded-xl" />
          <Skeleton className="h-40 rounded-xl" />
        </div>
      </div>
      <span className="sr-only">Đang tải...</span>
    </div>
  );
}
