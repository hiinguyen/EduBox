const HONORIFICS: ReadonlySet<string> = new Set(["cô", "thầy"]);

interface InitialsOptions {
  /** Drops a leading "Cô" or "Thầy" so teacher names yield the person's initials. */
  readonly shouldSkipHonorific?: boolean;
}

/**
 * Builds initials from the last `maxLetters` words of a name, which is the
 * given-name end in Vietnamese order.
 */
export function getInitials(
  name: string,
  maxLetters: number,
  { shouldSkipHonorific = false }: InitialsOptions = {},
): string {
  const words = name.trim().split(/\s+/).filter(Boolean);
  const [first = ""] = words;
  const nameWords =
    shouldSkipHonorific && words.length > 1 && HONORIFICS.has(first.toLowerCase())
      ? words.slice(1)
      : words;
  return nameWords
    .slice(-maxLetters)
    .map((word) => Array.from(word)[0]?.toUpperCase() ?? "")
    .join("");
}
