import Link from "next/link";
import { Icon } from "@/components/ui/icon";
import { ROLE_HOME, SIGN_IN_PATH } from "@/lib/auth/roles";
import { getSessionUser } from "@/lib/auth/session";

const HOME_LABEL = "Về trang của bạn";
const SIGN_IN_LABEL = "Đến trang đăng nhập";

// A failed session lookup must not turn the 404 page into a 500, so it falls back to sign-in.
async function resolveHome(): Promise<{ href: string; label: string }> {
  const user = await getSessionUser().catch(() => null);

  return user
    ? { href: ROLE_HOME[user.role], label: HOME_LABEL }
    : { href: SIGN_IN_PATH, label: SIGN_IN_LABEL };
}

/** Standalone on purpose: the root not-found has no app shell around it. */
export default async function NotFound() {
  const home = await resolveHome();

  return (
    <main className="grid min-h-screen place-items-center bg-surface px-gutter-mobile py-space-xl">
      <section
        aria-labelledby="not-found-title"
        className="w-full max-w-md rounded-xl bg-surface-container-lowest p-space-lg text-center shadow-level-1 md:p-space-xl"
      >
        <span className="mx-auto grid h-14 w-14 place-items-center rounded-full bg-primary-fixed text-on-primary-fixed">
          <Icon name="travel_explore" className="text-[28px]" />
        </span>
        <p className="mt-space-md font-label-sm text-label-sm uppercase tracking-wider text-on-surface-variant">
          Lỗi 404
        </p>
        <h1
          id="not-found-title"
          className="mt-space-xs font-headline-md text-headline-md text-on-surface"
        >
          Không tìm thấy trang
        </h1>
        <p className="mt-space-sm font-body-md text-body-md text-on-surface-variant">
          Trang bạn mở không tồn tại hoặc bạn không có quyền truy cập. Hãy quay lại trang của mình
          để tiếp tục.
        </p>
        <Link
          href={home.href}
          className="mt-space-lg inline-flex h-11 items-center justify-center rounded-lg bg-primary px-space-lg font-label-md text-label-md text-on-primary transition-colors hover:bg-primary-container focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2"
        >
          {home.label}
        </Link>
      </section>
    </main>
  );
}
