"use client";

import { createContext, useContext, type ReactNode } from "react";
import type { UserRole } from "@/lib/current-user";

const RoleContext = createContext<UserRole | null>(null);

interface RoleProviderProps {
  readonly role: UserRole;
  readonly children: ReactNode;
}

/** Makes the signed-in user's role available to client components such as the role switcher. */
export function RoleProvider({ role, children }: RoleProviderProps) {
  return <RoleContext.Provider value={role}>{children}</RoleContext.Provider>;
}

export function useRole(): UserRole | null {
  return useContext(RoleContext);
}
