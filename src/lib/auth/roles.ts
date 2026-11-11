import type { Role } from "@/generated/prisma/enums";

export const ROLES = ["STUDENT", "PARENT", "TEACHER"] as const satisfies readonly Role[];

export const ROLE_HOME = {
  STUDENT: "/hoc-tap",
  PARENT: "/phu-huynh",
  TEACHER: "/giao-vien",
} as const satisfies Record<Role, string>;

export const SIGN_IN_PATH = "/dang-nhap";
export const POST_LOGIN_PATH = "/dang-nhap/chuyen-huong";

export function isRole(value: unknown): value is Role {
  return typeof value === "string" && (ROLES as readonly string[]).includes(value);
}
