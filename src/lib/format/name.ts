/**
 * The given name part of a Vietnamese full name: drops the family name (first word) when
 * there is more than one word ("Nguyễn Minh Anh" -> "Minh Anh", "Hoa" -> "Hoa").
 */
export function getGivenName(fullName: string): string {
  const words = fullName.trim().split(/\s+/).filter(Boolean);
  return (words.length > 1 ? words.slice(1) : words).join(" ");
}
