import type { ExamSession } from "@/lib/thi-truc-tuyen/types";
import { ExamHeader } from "./exam-header";
import { ExamNotices } from "./exam-notices";
import { ExamProvider } from "./exam-provider";
import { ExamTools } from "./exam-tools";
import { ProctorNotice } from "./proctor-notice";
import { ProgressPanel } from "./progress-panel";
import { QuestionCard } from "./question-card";

interface ExamScreenProps {
  readonly session: ExamSession;
}

export function ExamScreen({ session }: ExamScreenProps) {
  const { exam, questions, tools } = session;

  return (
    <ExamProvider session={session}>
      <div className="flex w-full flex-col gap-space-lg">
        <ExamNotices />
        <ExamHeader exam={exam} questionCount={questions.length} />
        <div className="grid grid-cols-1 items-start gap-space-lg lg:grid-cols-12">
          <div className="flex w-full flex-col gap-space-md lg:col-span-4 xl:col-span-3">
            <ProgressPanel />
            <ExamTools tools={tools} />
            <ProctorNotice />
          </div>
          <section aria-label="Nội dung câu hỏi" className="w-full lg:col-span-8 xl:col-span-9">
            <QuestionCard />
          </section>
        </div>
      </div>
    </ExamProvider>
  );
}
