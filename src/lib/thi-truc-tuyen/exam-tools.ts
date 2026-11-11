import type { ExamTool } from "./types";

export const EXAM_TOOLS: readonly ExamTool[] = [
  {
    id: "formula",
    label: "Bảng công thức Toán học",
    icon: "functions",
    iconClassName: "text-primary",
  },
  {
    id: "calculator",
    label: "Máy tính bỏ túi mini Casio",
    icon: "calculate",
    iconClassName: "text-secondary",
  },
  { id: "scratchpad", label: "Bảng nháp vẽ tay số", icon: "draw", iconClassName: "text-tertiary" },
];
