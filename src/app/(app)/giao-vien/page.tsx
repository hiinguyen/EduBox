import type { Metadata } from "next";
import { notFound, redirect } from "next/navigation";
import { AiMatrixBanner } from "@/components/giao-vien/ai-matrix-banner";
import { GradingBoard } from "@/components/giao-vien/grading-board";
import { KnowledgeInsightsCard } from "@/components/giao-vien/knowledge-insights";
import { LectureLibrary } from "@/components/giao-vien/lecture-library";
import { StatsGrid } from "@/components/giao-vien/stats-grid";
import { WorkspaceHeader } from "@/components/giao-vien/workspace-header";
import { requireRole } from "@/lib/auth/session";
import {
  buildWorkspaceHref,
  parseWorkspaceQuery,
  type RawSearchParams,
} from "@/lib/giao-vien/query";
import type { TeacherWorkspace } from "@/lib/giao-vien/types";
import { findDefaultFocusTarget, getTeacherWorkspace } from "@/lib/giao-vien/workspace";

export const metadata: Metadata = { title: "Không gian Giáo viên" };

interface PageProps {
  readonly searchParams: Promise<RawSearchParams>;
}

function workspaceHref(workspace: TeacherWorkspace, lecturePage: number): string {
  const { grading } = workspace;
  return buildWorkspaceHref({
    classId: grading?.selection.classId,
    assessmentId: grading?.selection.assessmentId,
    page: grading?.pagination.page,
    submissionId: grading?.selected?.id,
    lecturePage,
  });
}

export default async function Page({ searchParams }: PageProps) {
  const user = await requireRole("TEACHER");
  const query = parseWorkspaceQuery(await searchParams);
  // Pin the default submission in the URL so saving a grade does not jump to the next one.
  // The cheap lookup runs first so a first visit never loads the whole workspace twice.
  const focus = await findDefaultFocusTarget(user, query);
  if (focus) redirect(buildWorkspaceHref({ ...query, ...focus }));

  const workspace = await getTeacherWorkspace(user, query);
  if (!workspace) notFound();

  const { teacher, stats, lectures, grading, insights } = workspace;
  return (
    <div className="flex w-full flex-col gap-space-lg">
      <WorkspaceHeader teacher={teacher} />
      <StatsGrid stats={stats} />
      <AiMatrixBanner />
      <LectureLibrary library={lectures} hrefForPage={(page) => workspaceHref(workspace, page)} />
      {grading ? (
        <GradingBoard
          board={grading}
          teacherName={teacher.shortName}
          lecturePage={lectures.pagination.page}
        >
          {insights ? <KnowledgeInsightsCard insights={insights} /> : null}
        </GradingBoard>
      ) : null}
    </div>
  );
}
