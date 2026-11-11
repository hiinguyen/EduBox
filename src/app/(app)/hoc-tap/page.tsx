import { AiTutor } from "@/components/hoc-tap/ai-tutor";
import { BadgeCard } from "@/components/hoc-tap/badge-card";
import { CourseSection } from "@/components/hoc-tap/course-section";
import { HomeworkCard } from "@/components/hoc-tap/homework-card";
import { LessonSection } from "@/components/hoc-tap/lesson-section";
import { MaterialsSection } from "@/components/hoc-tap/materials-section";
import { WelcomeBanner } from "@/components/hoc-tap/welcome-banner";
import { requireRole } from "@/lib/auth/session";
import { MATERIAL_FILTER_PARAM, parseMaterialFilter } from "@/lib/hoc-tap/materials";
import { getHocTapOverview } from "@/lib/hoc-tap/overview";

export const metadata = { title: "Học tập & Trợ lý AI" };

interface PageProps {
  readonly searchParams: Promise<Record<string, string | string[] | undefined>>;
}

export default async function Page({ searchParams }: PageProps) {
  const user = await requireRole("STUDENT");
  const materialFilter = parseMaterialFilter((await searchParams)[MATERIAL_FILTER_PARAM]);
  const overview = await getHocTapOverview(user, materialFilter);

  return (
    <div className="flex w-full flex-col gap-space-xl">
      <WelcomeBanner summary={overview.summary} />
      <div className="grid grid-cols-1 items-start gap-space-xl lg:grid-cols-12">
        <div className="flex min-w-0 flex-col gap-space-xl lg:col-span-8">
          <LessonSection lesson={overview.lesson} />
          <CourseSection courses={overview.courses} total={overview.courseTotal} />
          <MaterialsSection
            activeFilter={overview.materialFilter}
            filters={overview.materialFilters}
            materials={overview.materials}
          />
        </div>
        <div className="flex min-w-0 flex-col gap-space-lg lg:sticky lg:top-20 lg:col-span-4">
          <AiTutor
            initialMessages={overview.initialChat}
            initialThreadId={overview.chatThreadId}
            studentName={user.name}
          />
          <HomeworkCard homework={overview.homework} />
          {overview.badge ? <BadgeCard badge={overview.badge} /> : null}
        </div>
      </div>
    </div>
  );
}
