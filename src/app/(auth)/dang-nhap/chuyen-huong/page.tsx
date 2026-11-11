import { redirect } from "next/navigation";
import { SIGN_IN_PATH } from "@/lib/auth/roles";
import { resolvePostLoginPath } from "@/lib/auth/route-access";
import { getSessionUser } from "@/lib/auth/session";
import { readCallbackParam } from "../callback-param";

interface PostLoginPageProps {
  readonly searchParams: Promise<{ readonly callbackUrl?: string | string[] }>;
}

/**
 * Landing point right after sign-in. It is a page, not a route handler, because a Server Action
 * redirect to a route handler leaves the address bar on this URL and later actions POST to it.
 * Redirecting from a page makes the client router replace the URL with the real destination.
 */
export default async function PostLoginPage({ searchParams }: PostLoginPageProps) {
  const user = await getSessionUser();

  if (!user) {
    redirect(SIGN_IN_PATH);
  }

  const { callbackUrl } = await searchParams;
  redirect(resolvePostLoginPath(user.role, readCallbackParam(callbackUrl)));
}
