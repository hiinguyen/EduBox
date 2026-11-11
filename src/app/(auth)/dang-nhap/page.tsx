import type { Metadata } from "next";
import { redirect } from "next/navigation";
import { Icon } from "@/components/ui/icon";
import { ROLE_HOME } from "@/lib/auth/roles";
import { getSessionUser } from "@/lib/auth/session";
import { readCallbackParam } from "./callback-param";
import { SignInForm } from "./sign-in-form";

export const metadata: Metadata = { title: "Đăng nhập" };

interface SignInPageProps {
  readonly searchParams: Promise<{ readonly callbackUrl?: string | string[] }>;
}

export default async function SignInPage({ searchParams }: SignInPageProps) {
  const user = await getSessionUser();

  if (user) {
    redirect(ROLE_HOME[user.role]);
  }

  const { callbackUrl } = await searchParams;
  const safeCallback = readCallbackParam(callbackUrl);

  return (
    <main className="grid min-h-screen place-items-center bg-surface px-gutter-mobile py-space-xl">
      <div className="w-full max-w-md">
        <div className="mb-space-lg flex items-center justify-center gap-space-sm">
          <span className="grid h-10 w-10 place-items-center rounded-lg bg-primary-container text-on-primary">
            <Icon name="auto_stories" filled className="text-[24px]" />
          </span>
          <span className="font-headline-sm text-headline-sm tracking-tight text-primary">
            EduSmart
          </span>
        </div>
        <section
          aria-labelledby="sign-in-title"
          className="rounded-xl bg-surface-container-lowest p-space-lg shadow-sm md:p-space-xl"
        >
          <h1 id="sign-in-title" className="font-headline-md text-headline-md text-on-surface">
            Đăng nhập
          </h1>
          <p className="mt-space-xs font-body-sm text-body-sm text-on-surface-variant">
            Chào mừng trở lại. Đăng nhập để tiếp tục học tập cùng EduSmart.
          </p>
          <SignInForm callbackUrl={safeCallback} />
        </section>
      </div>
    </main>
  );
}
