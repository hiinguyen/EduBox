import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { ActivityLog } from "@/components/phu-huynh/activity-log";
import { CompanionSettings } from "@/components/phu-huynh/companion-settings";
import { ContactBook } from "@/components/phu-huynh/contact-book";
import { EffortHighlightCard } from "@/components/phu-huynh/effort-highlight";
import { NoChildrenState } from "@/components/phu-huynh/no-children-state";
import { ParentHeader } from "@/components/phu-huynh/parent-header";
import { ProgressChart } from "@/components/phu-huynh/progress-chart";
import { StatCards } from "@/components/phu-huynh/stat-cards";
import { UpcomingTasks } from "@/components/phu-huynh/upcoming-tasks";
import { dashboardSearchParamsSchema } from "@/lib/phu-huynh/schema";
import { requireRole } from "@/lib/auth/session";
import { getParentDashboard } from "@/lib/phu-huynh/dashboard";
import { toChildOption } from "@/lib/phu-huynh/view-model";

export const metadata: Metadata = { title: "Cổng Phụ huynh" };

interface PageProps {
  readonly searchParams: Promise<Record<string, string | string[] | undefined>>;
}

export default async function Page({ searchParams }: PageProps) {
  const user = await requireRole("PARENT");
  const params = dashboardSearchParamsSchema.safeParse(await searchParams);
  if (!params.success) notFound();

  const result = await getParentDashboard(user, params.data.con);
  if (result.status === "not-found") notFound();
  if (result.status === "no-children") return <NoChildrenState parentName={user.name} />;
  const { dashboard } = result;

  return (
    <div className="flex w-full flex-col gap-space-lg">
      <ParentHeader
        parent={dashboard.parent}
        academicYear={dashboard.academicYear}
        childOptions={dashboard.children.map(toChildOption)}
        selectedChildId={dashboard.selectedChild.id}
      />
      <StatCards stats={dashboard.stats} />
      <div className="grid grid-cols-1 gap-space-lg lg:grid-cols-12">
        <div className="flex min-w-0 flex-col gap-space-lg lg:col-span-7">
          <ProgressChart progress={dashboard.progress} />
          <ActivityLog entries={dashboard.activity} />
          <EffortHighlightCard effort={dashboard.effort} />
        </div>
        <div className="flex min-w-0 flex-col gap-space-lg lg:col-span-5">
          <ContactBook note={dashboard.teacherNote} />
          <UpcomingTasks tasks={dashboard.upcoming} />
          <CompanionSettings
            key={dashboard.selectedChild.id}
            childId={dashboard.selectedChild.id}
            settings={dashboard.settings}
            devices={dashboard.linkedDevices}
          />
        </div>
      </div>
    </div>
  );
}
