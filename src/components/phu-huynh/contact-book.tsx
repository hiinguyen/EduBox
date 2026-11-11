import { Avatar } from "@/components/ui/avatar";
import { DisabledNavItem } from "@/components/app-shell/disabled-nav-item";
import { Icon } from "@/components/ui/icon";
import { Pill } from "@/components/ui/pill";
import { SectionPanel } from "@/components/ui/section-panel";
import type { TeacherNote } from "@/lib/phu-huynh/types";
import { AcknowledgeNoteButton } from "./acknowledge-note-button";

interface ContactBookProps {
  readonly note: TeacherNote | null;
}

const MESSAGE_TEACHER_LABEL = "Nhắn tin trao đổi với giáo viên";

function AcknowledgementStatus({ note }: { readonly note: TeacherNote }) {
  if (!note.isAcknowledged) return <AcknowledgeNoteButton noteId={note.id} />;
  return (
    <>
      <span>Đã xác nhận bởi Phụ huynh</span>
      <span className="flex items-center gap-1 font-semibold text-tertiary">
        <Icon name="done_all" className="text-[16px]" /> Đã đọc
      </span>
    </>
  );
}

function NoteArticle({ note }: { readonly note: TeacherNote }) {
  return (
    <article className="flex flex-col gap-space-sm rounded-xl bg-surface-container-low p-space-md">
      <header className="flex items-center gap-space-sm">
        <Avatar name={note.teacherName} size="lg" shouldSkipHonorific />
        <div>
          <p className="flex flex-wrap items-center gap-1.5">
            <span className="font-label-md text-label-md font-bold text-on-surface">
              {note.teacherName}
            </span>
            <span className="rounded bg-primary-fixed px-1.5 py-0.5 font-label-sm text-label-sm text-on-primary-fixed">
              {note.subject}
            </span>
          </p>
          <p className="font-body-sm text-body-sm text-on-surface-variant">
            {note.role} · {note.sentAgo}
          </p>
        </div>
      </header>
      <blockquote className="relative rounded-lg bg-surface-container-lowest p-space-sm">
        <Icon
          name="format_quote"
          className="absolute right-2 top-2 text-[24px] text-surface-container-high"
        />
        <p className="font-body-sm text-body-sm italic leading-relaxed text-on-surface">
          &ldquo;{note.message}&rdquo;
        </p>
      </blockquote>
      <footer className="flex items-center justify-between pt-1 font-label-sm text-label-sm text-on-surface-variant">
        <AcknowledgementStatus note={note} />
      </footer>
    </article>
  );
}

export function ContactBook({ note }: ContactBookProps) {
  return (
    <SectionPanel
      icon="quick_reference"
      title="Sổ liên lạc điện tử"
      aside={note ? <Pill tone="success">{note.weekLabel}</Pill> : undefined}
    >
      {note ? (
        <NoteArticle note={note} />
      ) : (
        <p className="rounded-xl bg-surface-container-low p-space-md font-body-sm text-body-sm text-on-surface-variant">
          Chưa có nhận xét nào từ giáo viên.
        </p>
      )}
      <DisabledNavItem
        label={MESSAGE_TEACHER_LABEL}
        hasAriaLabel
        className="flex h-11 w-full items-center justify-center gap-2 rounded-lg bg-primary font-label-md text-label-md text-on-primary shadow-sm"
      >
        <Icon name="forum" className="text-[18px]" />
        <span>{MESSAGE_TEACHER_LABEL}</span>
      </DisabledNavItem>
    </SectionPanel>
  );
}
