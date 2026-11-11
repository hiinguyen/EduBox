import { Card } from "@/components/ui/card";
import { Icon } from "@/components/ui/icon";
import type { ExamTool } from "@/lib/thi-truc-tuyen/types";

const COMING_SOON_LABEL = "Sắp ra mắt";

interface ExamToolsProps {
  readonly tools: readonly ExamTool[];
}

export function ExamTools({ tools }: ExamToolsProps) {
  return (
    <Card
      as="section"
      aria-labelledby="exam-tools-title"
      className="flex flex-col gap-space-sm p-space-md"
    >
      <h2
        id="exam-tools-title"
        className="flex items-center gap-1.5 font-headline-sm text-label-md font-semibold text-on-surface"
      >
        <Icon name="handyman" className="text-[20px] text-primary" />
        Công cụ hỗ trợ thi
      </h2>
      <ul className="mt-1 flex flex-col gap-2">
        {tools.map((tool) => (
          <li key={tool.id}>
            <button
              type="button"
              disabled
              aria-disabled="true"
              title={COMING_SOON_LABEL}
              className="group flex w-full items-center justify-between rounded-lg bg-surface-container p-2.5 text-left font-label-md text-label-md text-on-surface disabled:cursor-not-allowed disabled:opacity-60"
            >
              <span className="flex items-center gap-2">
                <Icon name={tool.icon} className={`text-[20px] ${tool.iconClassName}`} />
                <span>{tool.label}</span>
              </span>
              <Icon
                name="open_in_new"
                className="text-[18px] text-outline transition-transform group-hover:translate-x-0.5"
              />
            </button>
          </li>
        ))}
      </ul>
    </Card>
  );
}
