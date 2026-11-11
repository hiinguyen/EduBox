import { useId } from "react";
import type { ReactNode } from "react";
import { Icon } from "@/components/ui/icon";
import { Card } from "@/components/ui/card";
import { TONE_TEXT_CLASS, type Tone } from "@/lib/ui/tone";

export type HeadingLevel = 2 | 3 | 4;

interface SectionPanelProps {
  readonly title: string;
  readonly headingLevel?: HeadingLevel;
  readonly icon?: string;
  readonly iconTone?: Tone;
  readonly aside?: ReactNode;
  readonly className?: string;
  readonly children: ReactNode;
}

export function SectionPanel({
  title,
  headingLevel = 2,
  icon,
  iconTone = "primary",
  aside,
  className,
  children,
}: SectionPanelProps) {
  const headingId = useId();
  const Heading = `h${headingLevel}` as const;
  return (
    <Card
      as="section"
      aria-labelledby={headingId}
      className={`flex flex-col gap-space-md ${className ?? ""}`}
    >
      <div className="flex items-center justify-between gap-space-sm">
        <div className="flex items-center gap-space-xs">
          {icon ? (
            <Icon name={icon} className={`text-[22px] ${TONE_TEXT_CLASS[iconTone]}`} />
          ) : null}
          <Heading id={headingId} className="font-headline-sm text-headline-sm text-on-surface">
            {title}
          </Heading>
        </div>
        {aside}
      </div>
      {children}
    </Card>
  );
}
