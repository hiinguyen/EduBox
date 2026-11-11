import { Icon } from "@/components/ui/icon";
import { ComingSoonButton } from "./coming-soon-button";

export function AiMatrixBanner() {
  return (
    <section
      aria-labelledby="ai-matrix-title"
      className="flex flex-col items-center justify-between gap-space-md rounded-xl bg-gradient-to-r from-primary/10 via-surface-container-high to-secondary-fixed/40 p-space-lg shadow-sm xl:flex-row"
    >
      <div className="flex min-w-0 items-center gap-space-md">
        <div className="flex h-12 w-12 shrink-0 items-center justify-center rounded-xl bg-surface-container-lowest text-secondary shadow-sm">
          <Icon name="psychology" filled className="text-[28px]" />
        </div>
        <div className="flex flex-col">
          <h2 id="ai-matrix-title" className="font-headline-sm text-headline-sm text-on-surface">
            Công cụ thiết kế ma trận đề thông minh cùng EduSmart AI
          </h2>
          <p className="font-body-sm text-body-sm text-on-surface-variant">
            Tạo tự động bộ câu hỏi chuẩn định dạng THPT Quốc gia theo 4 bậc nhận thức chỉ trong vài
            giây.
          </p>
        </div>
      </div>
      <ComingSoonButton className="flex items-center gap-space-xs rounded-lg bg-secondary px-space-lg py-3 text-left font-label-md text-label-md text-on-secondary shadow-md xl:whitespace-nowrap">
        <Icon name="smart_toy" className="shrink-0 text-[20px]" />
        <span>
          Tạo bộ câu hỏi phân hóa bằng AI (Nhận biết - Thông hiểu - Vận dụng - Vận dụng cao)
        </span>
      </ComingSoonButton>
    </section>
  );
}
