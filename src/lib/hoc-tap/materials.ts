import { z } from "zod";
import type { MaterialFilter, MaterialFilterOption, SubjectKey } from "./types";

export const SUBJECT_ORDER = [
  "math",
  "physics",
  "chemistry",
  "english",
] as const satisfies readonly SubjectKey[];

export const MATERIAL_FILTER_PARAM = "mon";

export const SUBJECT_LABELS: Readonly<Record<SubjectKey, string>> = {
  math: "Toán",
  physics: "Vật lý",
  chemistry: "Hóa học",
  english: "Tiếng Anh",
};

const materialFilterSchema = z.enum(["all", ...SUBJECT_ORDER]).catch("all");

/** Reads the `mon` query param; anything unknown (or repeated) falls back to "all". */
export function parseMaterialFilter(raw: unknown): MaterialFilter {
  return materialFilterSchema.parse(raw);
}

export function materialFilterHref(filter: MaterialFilter): string {
  return filter === "all" ? "/hoc-tap" : `/hoc-tap?${MATERIAL_FILTER_PARAM}=${filter}`;
}

/** One chip per subject that actually has materials, after the "all" chip. */
export function buildMaterialFilters(
  presentSubjects: readonly SubjectKey[],
): readonly MaterialFilterOption[] {
  const present = new Set(presentSubjects);
  const subjects = SUBJECT_ORDER.filter((subject) => present.has(subject));
  return [
    { value: "all", label: "Tất cả" },
    ...subjects.map((subject) => ({ value: subject, label: SUBJECT_LABELS[subject] })),
  ];
}
