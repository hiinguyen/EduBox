import { Icon } from "@/components/ui/icon";
import { ComingSoonButton } from "./coming-soon-button";

export function TutorHeader() {
  return (
    <div className="flex flex-col gap-space-xs bg-gradient-to-r from-secondary-container to-primary p-space-md text-on-secondary">
      <div className="flex items-center justify-between gap-space-sm">
        <div className="flex items-center gap-space-sm">
          <div
            aria-hidden="true"
            className="flex h-9 w-9 shrink-0 items-center justify-center rounded-full bg-white/20 backdrop-blur-md"
          >
            <Icon name="psychology" className="text-[22px] text-white" />
          </div>
          <div>
            <h2
              id="tutor-heading"
              className="font-headline-sm text-headline-sm leading-tight text-white"
            >
              Gia sư AI Socratic
            </h2>
            <span className="flex items-center gap-1 font-label-sm text-label-sm text-secondary-fixed">
              <span
                aria-hidden="true"
                className="inline-block h-2 w-2 shrink-0 rounded-full bg-tertiary-fixed"
              />
              Sẵn sàng phản biện & hướng dẫn tư duy
            </span>
          </div>
        </div>
        <ComingSoonButton label="Làm mới cuộc trò chuyện" className="rounded-lg p-1 text-white">
          <Icon name="restart_alt" className="text-[20px]" />
        </ComingSoonButton>
      </div>
      <p className="mt-1 flex items-start gap-1.5 rounded-lg bg-black/20 px-2.5 py-1.5 font-label-sm text-label-sm leading-snug text-secondary-fixed">
        <Icon name="school" className="mt-0.5 flex-shrink-0 text-[16px] text-tertiary-fixed" />
        <span>
          <strong>Nguyên tắc Socratic:</strong> AI sẽ đặt câu hỏi gợi mở từng bước, không giải hộ
          bài toán.
        </span>
      </p>
    </div>
  );
}
