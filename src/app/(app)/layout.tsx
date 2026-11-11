import type { ReactNode } from "react";
import { AppShell } from "@/components/app-shell/app-shell";
import { RoleProvider } from "@/components/app-shell/role-context";
import { getShellUser } from "@/lib/auth/shell-user";

export default async function AppLayout({ children }: { readonly children: ReactNode }) {
  const user = await getShellUser();

  return (
    <RoleProvider role={user.role}>
      <AppShell user={user}>{children}</AppShell>
    </RoleProvider>
  );
}
