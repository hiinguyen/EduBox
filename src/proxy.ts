import { NextResponse } from "next/server";
import NextAuth from "next-auth";
import { authConfig } from "@/lib/auth/config";
import { decideRouteAccess, buildSignInUrl } from "@/lib/auth/route-access";
import { isRole } from "@/lib/auth/roles";

const NOT_FOUND_STATUS = 404;
const { auth } = NextAuth(authConfig);

/**
 * Coarse gate in front of the four screens: anonymous visitors go to /dang-nhap and a
 * signed-in user with the wrong role gets a 404. Pages and actions still enforce roles
 * with requireRole / requireRoleForAction, which read the role fresh from the database.
 */
export default auth((request) => {
  const rawRole = request.auth?.user?.role;
  const role = isRole(rawRole) ? rawRole : null;
  const { pathname, search, origin } = request.nextUrl;
  const decision = decideRouteAccess(pathname, role);

  if (decision.type === "login") {
    return NextResponse.redirect(new URL(buildSignInUrl(`${pathname}${search}`), origin));
  }
  if (decision.type === "forbidden") {
    return NextResponse.rewrite(new URL("/khong-tim-thay", origin), { status: NOT_FOUND_STATUS });
  }
  return NextResponse.next();
});

export const config = {
  matcher: ["/hoc-tap/:path*", "/thi-truc-tuyen/:path*", "/phu-huynh/:path*", "/giao-vien/:path*"],
};
