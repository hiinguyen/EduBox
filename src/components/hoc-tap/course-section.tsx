import { DisabledNavItem } from "@/components/app-shell/disabled-nav-item";
import { Icon } from "@/components/ui/icon";
import { ProgressBar } from "@/components/ui/progress-bar";
import { TONE_TEXT_CLASS } from "@/lib/ui/tone";
import type { CourseCard } from "@/lib/hoc-tap/types";
import { ComingSoonButton } from "./coming-soon-button";
import { CARD_TONE_CLASSES } from "./tone";

interface CourseSectionProps {
  readonly courses: readonly CourseCard[];
  readonly total: number;
}

function CourseItem({ course }: { readonly course: CourseCard }) {
  const tone = CARD_TONE_CLASSES[course.tone];
  const textClass = TONE_TEXT_CLASS[course.tone];
  return (
    <article className="group flex flex-col justify-between overflow-hidden rounded-xl bg-surface-container-lowest shadow-sm transition-shadow hover:shadow-md">
      <div
        className={`relative flex h-36 w-full items-center justify-center overflow-hidden bg-gradient-to-br ${tone.gradient}`}
      >
        <Icon name={course.icon} className={`text-[64px] ${tone.tint}`} />
        <span
          className={`absolute left-2 top-2 rounded bg-surface-container-lowest/90 px-2 py-0.5 font-label-sm text-label-sm font-bold backdrop-blur-md ${textClass}`}
        >
          {course.subject}
        </span>
        <span className="absolute bottom-2 right-2 rounded bg-black/70 px-2 py-0.5 font-label-sm text-label-sm text-on-primary">
          {course.durationMinutes} phút
        </span>
      </div>
      <div className="flex flex-1 flex-col justify-between gap-space-md p-space-md">
        <div>
          <h3
            className={`line-clamp-1 font-headline-sm text-headline-sm text-on-surface transition-colors ${tone.hoverTitle}`}
            title={course.title}
          >
            {course.title}
          </h3>
          <p className="mt-1 font-body-sm text-body-sm text-on-surface-variant">
            {course.instructor}
          </p>
        </div>
        <div className="flex flex-col gap-1.5">
          <div className="flex justify-between font-label-sm text-label-sm text-on-surface-variant">
            <span>Tiến độ hoàn thành</span>
            <span className={`font-semibold ${textClass}`}>{course.progressPercent}%</span>
          </div>
          <ProgressBar
            value={course.progressPercent}
            label={`Tiến độ ${course.title}`}
            tone={course.tone}
            className="h-1.5"
          />
          <ComingSoonButton
            className={`mt-2 flex w-full items-center justify-center gap-1.5 rounded-lg bg-surface-container-high py-2 font-label-md text-label-md text-on-surface transition-colors ${tone.hoverButton}`}
          >
            <Icon name="play_circle" className="text-[18px]" />
            <span>Tiếp tục học</span>
            <span className="sr-only">{course.title}</span>
          </ComingSoonButton>
        </div>
      </div>
    </article>
  );
}

export function CourseSection({ courses, total }: CourseSectionProps) {
  return (
    <section aria-labelledby="courses-heading" className="flex flex-col gap-space-md">
      <div className="flex items-center justify-between gap-space-md">
        <div className="flex items-center gap-space-sm">
          <span aria-hidden="true" className="h-6 w-2.5 rounded-full bg-primary" />
          <h2 id="courses-heading" className="font-headline-md text-headline-md text-on-surface">
            Khóa học & Bài giảng tiếp theo
          </h2>
        </div>
        <DisabledNavItem
          label="Xem tất cả khóa học"
          className="flex shrink-0 items-center gap-0.5 rounded font-label-md text-label-md text-primary"
        >
          Xem tất cả ({total})
          <Icon name="chevron_right" className="text-[18px]" />
        </DisabledNavItem>
      </div>
      <div className="grid grid-cols-1 gap-space-md md:grid-cols-3">
        {courses.map((course) => (
          <CourseItem key={course.id} course={course} />
        ))}
      </div>
    </section>
  );
}
