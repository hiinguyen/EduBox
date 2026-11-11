export interface TextPart {
  readonly text: string;
  readonly isHighlight: boolean;
}

export function splitByHighlight(text: string, highlight: string | undefined): readonly TextPart[] {
  const start = highlight ? text.indexOf(highlight) : -1;
  if (!highlight || start < 0) return [{ text, isHighlight: false }];

  const end = start + highlight.length;
  return [
    { text: text.slice(0, start), isHighlight: false },
    { text: highlight, isHighlight: true },
    { text: text.slice(end), isHighlight: false },
  ].filter((part) => part.text.length > 0);
}
