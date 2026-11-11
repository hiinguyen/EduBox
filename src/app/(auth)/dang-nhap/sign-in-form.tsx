"use client";

import { useActionState, useState } from "react";
import { signInAction, type SignInState } from "@/lib/auth/actions";

const INITIAL_STATE: SignInState = { error: null };
const FIELD_CLASS =
  "mt-space-xs h-11 w-full rounded-lg border border-outline-variant bg-surface-container-lowest px-space-md font-body-md text-body-md text-on-surface placeholder:text-outline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary";
const LABEL_CLASS = "font-label-md text-label-md text-on-surface";

interface SignInFormProps {
  readonly callbackUrl: string | null;
}

export function SignInForm({ callbackUrl }: SignInFormProps) {
  const [state, formAction, isPending] = useActionState(signInAction, INITIAL_STATE);
  // Controlled so a failed attempt does not wipe the email when React resets the form.
  const [email, setEmail] = useState("");

  return (
    <form action={formAction} className="mt-space-lg flex flex-col gap-space-md" noValidate>
      {callbackUrl ? <input type="hidden" name="callbackUrl" value={callbackUrl} /> : null}

      <div role="alert" className="empty:hidden">
        {state.error ? (
          <p className="rounded-lg bg-error-container px-space-md py-space-sm font-body-sm text-body-sm text-on-error-container">
            {state.error}
          </p>
        ) : null}
      </div>

      <div>
        <label htmlFor="email" className={LABEL_CLASS}>
          Email
        </label>
        <input
          id="email"
          name="email"
          type="email"
          inputMode="email"
          autoComplete="username"
          value={email}
          onChange={(event) => setEmail(event.target.value)}
          required
          readOnly={isPending}
          placeholder="ten@truong.edu.vn"
          aria-invalid={state.error ? true : undefined}
          className={FIELD_CLASS}
        />
      </div>

      <div>
        <label htmlFor="password" className={LABEL_CLASS}>
          Mật khẩu
        </label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          readOnly={isPending}
          aria-invalid={state.error ? true : undefined}
          className={FIELD_CLASS}
        />
      </div>

      <button
        type="submit"
        disabled={isPending}
        className="mt-space-sm h-11 rounded-lg bg-primary px-space-md font-label-md text-label-md text-on-primary transition-colors hover:bg-primary-container focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-primary focus-visible:ring-offset-2 disabled:cursor-not-allowed disabled:opacity-70"
      >
        {isPending ? "Đang đăng nhập..." : "Đăng nhập"}
      </button>
    </form>
  );
}
