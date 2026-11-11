export interface Screen {
  readonly href: string;
  readonly title: string;
  readonly description: string;
}

export const SCREENS = [
  {
    href: "/hoc-tap",
    title: "Học tập & Trợ lý AI",
    description: "Bài học và trợ lý AI cho học sinh.",
  },
  {
    href: "/thi-truc-tuyen",
    title: "Làm bài & Thi trực tuyến",
    description: "Làm bài tập và thi online.",
  },
  {
    href: "/giao-vien",
    title: "Không gian Giáo viên",
    description: "Quản lý lớp, bài giảng, chấm điểm.",
  },
  {
    href: "/phu-huynh",
    title: "Cổng Phụ huynh",
    description: "Theo dõi tiến độ học của con.",
  },
] as const satisfies readonly Screen[];

export type ScreenHref = (typeof SCREENS)[number]["href"];

export function getScreen(href: ScreenHref): Screen {
  const screen = SCREENS.find((candidate) => candidate.href === href);

  if (!screen) {
    throw new Error(`Unknown screen href: ${href}`);
  }

  return screen;
}
