import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";

interface NoChildrenStateProps {
  readonly parentName: string;
}

export function NoChildrenState({ parentName }: NoChildrenStateProps) {
  return (
    <Card
      as="section"
      aria-labelledby="no-children-title"
      className="flex w-full flex-col items-center gap-space-sm py-space-xl text-center"
    >
      <span className="flex h-14 w-14 items-center justify-center rounded-full bg-secondary-fixed">
        <Icon name="shield_person" filled className="text-[32px] text-secondary" />
      </span>
      <h1 id="no-children-title" className="font-headline-md text-headline-md text-on-surface">
        Chưa có hồ sơ học sinh nào được liên kết
      </h1>
      <p className="max-w-prose font-body-md text-body-md text-on-surface-variant">
        Xin chào {parentName}. Tài khoản của bạn chưa được liên kết với hồ sơ của con. Vui lòng liên
        hệ nhà trường để được liên kết, sau đó quay lại trang này.
      </p>
    </Card>
  );
}
