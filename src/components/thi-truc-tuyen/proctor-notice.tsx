import { Icon } from "@/components/ui/icon";

export function ProctorNotice() {
  return (
    <aside
      aria-labelledby="proctor-notice-title"
      className="flex flex-col gap-space-xs rounded-xl bg-secondary-fixed/40 p-space-md text-on-secondary-fixed shadow-sm"
    >
      <h2
        id="proctor-notice-title"
        className="flex items-center gap-2 font-label-md text-label-md font-bold"
      >
        <Icon name="smart_toy" className="text-[22px] text-secondary" />
        Trợ lý AI Giám thị EduSmart
      </h2>
      <p className="font-body-sm text-body-sm leading-relaxed">
        Lưu ý trong phòng thi: Trợ lý AI đã được chuyển sang chế độ{" "}
        <span className="font-semibold">Giám thị &amp; Hỗ trợ kỹ thuật</span> (không giải đáp kiến
        thức trong giờ thi chính thức). Mọi hành vi chuyển tab đều được ghi nhận lại.
      </p>
      <p className="mt-1 flex items-center gap-2 font-label-sm text-label-sm font-medium">
        <span className="h-2 w-2 rounded-full bg-tertiary" aria-hidden="true" />
        Bảo mật phòng thi: An toàn 100%
      </p>
    </aside>
  );
}
