import type { ReactNode } from "react";
import type { CurrentUser } from "@/lib/current-user";
import { MobileNavigation } from "./mobile-navigation";
import { Sidebar } from "./sidebar";
import { TopBar } from "./top-bar";

const MAIN_CONTENT_ID = "main-content";

interface AppShellProps {
  readonly user: CurrentUser;
  readonly children: ReactNode;
}

export function AppShell({ user, children }: AppShellProps) {
  return (
    <div className="min-h-screen bg-surface">
      <a
        href={`#${MAIN_CONTENT_ID}`}
        className="sr-only z-[60] rounded-lg bg-primary px-space-md py-space-sm font-label-md text-label-md text-on-primary focus:not-sr-only focus:fixed focus:left-space-md focus:top-space-md"
      >
        Bỏ qua đến nội dung chính
      </a>
      <TopBar user={user} />
      <Sidebar role={user.role} />
      <MobileNavigation role={user.role} />
      <div className="md:pl-20 lg:pl-72">
        <main
          id={MAIN_CONTENT_ID}
          tabIndex={-1}
          className="min-h-screen bg-surface px-gutter-mobile pb-28 outline-none md:px-gutter pt-24 md:pb-space-xl"
        >
          {children}
        </main>
      </div>
    </div>
  );
}
