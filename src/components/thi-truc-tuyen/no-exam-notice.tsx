import { Icon } from "@/components/ui/icon";

export function NoExamNotice() {
  return (
    <div
      role="status"
      className="mx-auto flex max-w-md flex-col items-center gap-space-md rounded-xl bg-surface-container-lowest p-space-xl text-center shadow-sm"
    >
      <Icon name="event_busy" className="text-[40px] text-on-surface-variant" />
      <h1 className="font-headline-sm text-headline-sm text-on-surface">Chưa có bài thi nào</h1>
      <p className="font-body-md text-body-md text-on-surface-variant">
        Hiện chưa có bài thi trực tuyến dành cho lớp của bạn. Khi giáo viên mở bài thi, bạn sẽ thấy
        bài ở đây.
      </p>
    </div>
  );
}
