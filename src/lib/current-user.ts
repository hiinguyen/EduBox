export type UserRole = "STUDENT" | "PARENT" | "TEACHER";

/** What the app shell displays about the signed-in user. Built by getShellUser (server-only). */
export interface CurrentUser {
  readonly name: string;
  readonly initials: string;
  readonly role: UserRole;
  readonly description: string;
}
