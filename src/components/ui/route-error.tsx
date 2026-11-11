"use client";

import { Icon } from "@/components/ui/icon";

interface RouteErrorProps {
  readonly screenTitle: string;
  readonly reset: () => void;
}

export function RouteError({ screenTitle, reset }: RouteErrorProps) {
  return (
    <div
      role="alert"
      className="mx-auto flex max-w-md flex-col items-center gap-space-md rounded-xl bg-surface-container-lowest p-space-xl text-center shadow-sm"
    >
      <Icon name="error" className="text-[40px] text-error" />
      <h1 className="font-headline-sm text-headline-sm text-on-surface">
        Không thể tải {screenTitle}
      </h1>
      <p className="font-body-md text-body-md text-on-surface-variant">
        Đã có lỗi xảy ra. Vui lòng thử lại sau ít phút.
      </p>
      <button
        type="button"
        onClick={reset}
        className="rounded-lg bg-primary px-space-lg py-space-sm font-label-md text-label-md font-medium text-on-primary transition-colors hover:bg-primary-container"
      >
        Thử lại
      </button>
    </div>
  );
}
