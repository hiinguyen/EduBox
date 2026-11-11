import type { CardTone } from "@/lib/hoc-tap/types";

interface CardToneClasses {
  readonly hoverTitle: string;
  readonly hoverButton: string;
  readonly gradient: string;
  readonly tint: string;
}

/** Card-only accents; shared text, background and bar classes come from `@/lib/ui/tone`. */
export const CARD_TONE_CLASSES: Readonly<Record<CardTone, CardToneClasses>> = {
  primary: {
    hoverTitle: "group-hover:text-primary",
    hoverButton: "hover:bg-primary hover:text-on-primary",
    gradient: "from-primary-fixed to-primary-fixed-dim",
    tint: "text-primary/40",
  },
  secondary: {
    hoverTitle: "group-hover:text-secondary",
    hoverButton: "hover:bg-secondary hover:text-on-secondary",
    gradient: "from-secondary-fixed to-secondary-fixed-dim",
    tint: "text-secondary/40",
  },
  tertiary: {
    hoverTitle: "group-hover:text-tertiary",
    hoverButton: "hover:bg-tertiary hover:text-on-tertiary",
    gradient: "from-tertiary-fixed to-tertiary-fixed-dim",
    tint: "text-tertiary/40",
  },
};
