import type { Metadata } from "next";
import { notFound } from "next/navigation";
import { ExamIntro } from "@/components/thi-truc-tuyen/exam-intro";
import { ExamScreen } from "@/components/thi-truc-tuyen/exam-screen";
import { NoExamNotice } from "@/components/thi-truc-tuyen/no-exam-notice";
import { requireRole } from "@/lib/auth/session";
import { getExamPage } from "@/lib/thi-truc-tuyen/exam-session";
import { assessmentQuerySchema } from "@/lib/thi-truc-tuyen/schemas";

export const metadata: Metadata = { title: "Làm bài & Thi trực tuyến" };

interface PageProps {
  readonly searchParams: Promise<Record<string, string | string[] | undefined>>;
}

/** The exam id is optional; a malformed value is a 404, never a fallback to another exam. */
function parseRequestedId(raw: string | string[] | undefined): string | undefined {
  if (raw === undefined) return undefined;
  const parsed = assessmentQuerySchema.safeParse(raw);
  if (!parsed.success) notFound();
  return parsed.data;
}

/** Opening the page is read only: the exam starts through the `startAttempt` action. */
export default async function Page({ searchParams }: PageProps) {
  const user = await requireRole("STUDENT");
  const requestedId = parseRequestedId((await searchParams).assessmentId);
  const page = await getExamPage(user, requestedId);

  if (page.kind === "session") return <ExamScreen session={page.session} />;
  if (page.kind === "intro") return <ExamIntro intro={page.intro} />;
  if (requestedId !== undefined) notFound();
  return <NoExamNotice />;
}
