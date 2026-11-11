import { Icon } from "@/components/ui/icon";
import { SectionPanel } from "@/components/ui/section-panel";
import type { DeadlineBadge, UpcomingTask } from "@/lib/phu-huynh/types";

const BADGE_BOX = "flex h-12 w-12 shrink-0 flex-col items-center justify-center rounded-lg";
const BADGE_CAPTION = "text-[9px] uppercase";

function TaskBadge({
  badge,
  isUrgent,
}: {
  readonly badge: DeadlineBadge;
  readonly isUrgent: boolean;
}) {
  const tone = isUrgent
    ? "bg-error-container text-on-error-container"
    : "bg-secondary-fixed text-on-secondary-fixed";
  switch (badge.kind) {
    case "countdown":
      return (
        <div className={`${BADGE_BOX} ${tone}`}>
          <span className="font-label-sm text-label-sm font-bold leading-none">{badge.value}</span>
          <span className={`${BADGE_CAPTION} tracking-tighter`}>{badge.caption}</span>
        </div>
      );
    case "icon":
      return (
        <div className={`${BADGE_BOX} ${tone}`}>
          <Icon name={badge.icon} className="text-[18px]" />
          <span className={`${BADGE_CAPTION} font-semibold`}>{badge.caption}</span>
        </div>
      );
    default: {
      const unreachable: never = badge;
      return unreachable;
    }
  }
}

function TaskItem({ task }: { readonly task: UpcomingTask }) {
  return (
    <li className="flex items-start gap-space-sm rounded-lg bg-surface-container-low p-space-sm transition-colors hover:bg-surface-container">
      <TaskBadge badge={task.badge} isUrgent={task.isUrgent} />
      <div className="min-w-0 flex-1">
        <div className="flex items-center justify-between gap-space-xs">
          <h3 className="truncate font-label-md text-label-md font-semibold text-on-surface">
            {task.title}
          </h3>
          <span
            className={`shrink-0 font-label-sm text-label-sm font-semibold ${task.isUrgent ? "text-error" : "text-secondary"}`}
          >
            {task.dueLabel}
          </span>
        </div>
        <p className="truncate font-body-sm text-body-sm text-on-surface-variant">
          {task.subtitle}
        </p>
      </div>
    </li>
  );
}

interface UpcomingTasksProps {
  readonly tasks: readonly UpcomingTask[];
}

export function UpcomingTasks({ tasks }: UpcomingTasksProps) {
  return (
    <SectionPanel
      icon="event_upcoming"
      iconTone="secondary"
      title="Lịch nộp bài & Kỳ thi sắp tới"
      aside={
        <span className="shrink-0 font-label-sm text-label-sm text-on-surface-variant">
          {tasks.length} việc cần chú ý
        </span>
      }
    >
      {tasks.length === 0 ? (
        <p className="font-body-sm text-body-sm text-on-surface-variant">
          Không có bài tập hay kỳ thi nào sắp đến hạn.
        </p>
      ) : (
        <ul className="flex flex-col gap-space-sm">
          {tasks.map((task) => (
            <TaskItem key={task.id} task={task} />
          ))}
        </ul>
      )}
    </SectionPanel>
  );
}
