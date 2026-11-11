import { getInitials } from "@/lib/format/initials";
import { TONE_BG_CLASS, type Tone } from "@/lib/ui/tone";

export type AvatarSize = "sm" | "md" | "lg";

const SIZE_CLASS: Readonly<Record<AvatarSize, string>> = {
  sm: "h-8 w-8 text-label-sm",
  md: "h-10 w-10 text-label-md",
  lg: "h-11 w-11 text-label-md",
};

const AVATAR_INITIAL_LETTERS = 2;

interface AvatarProps {
  readonly name: string;
  readonly size?: AvatarSize;
  readonly tone?: Tone;
  /** Accessible name. Omit when the name is already rendered next to the avatar. */
  readonly label?: string;
  readonly maxLetters?: number;
  readonly shouldSkipHonorific?: boolean;
}

export function Avatar({
  name,
  size = "md",
  tone = "secondary",
  label,
  maxLetters = AVATAR_INITIAL_LETTERS,
  shouldSkipHonorific = false,
}: AvatarProps) {
  const accessibility = label ? { role: "img", "aria-label": label } : { "aria-hidden": true };
  return (
    <span
      {...accessibility}
      className={`flex shrink-0 items-center justify-center rounded-full font-semibold ${SIZE_CLASS[size]} ${TONE_BG_CLASS[tone]}`}
    >
      {getInitials(name, maxLetters, { shouldSkipHonorific })}
    </span>
  );
}
