export type TabKey = "ArrowLeft" | "ArrowRight" | "Home" | "End";

/** Returns the index to move to for a tablist key press, or null when the key is not handled. */
export function getNextTabIndex(
  key: string,
  currentIndex: number,
  tabCount: number,
): number | null {
  if (tabCount <= 0) return null;
  switch (key as TabKey) {
    case "ArrowRight":
      return (currentIndex + 1) % tabCount;
    case "ArrowLeft":
      return (currentIndex - 1 + tabCount) % tabCount;
    case "Home":
      return 0;
    case "End":
      return tabCount - 1;
    default:
      return null;
  }
}
