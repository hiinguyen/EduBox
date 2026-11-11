"use server";

import { AuthError, CredentialsSignin } from "next-auth";
import { signIn, signOut } from "./auth";
import { POST_LOGIN_PATH, SIGN_IN_PATH } from "./roles";
import { sanitizeCallbackPath } from "./route-access";
import { signInSchema } from "./schemas";

export interface SignInState {
  readonly error: string | null;
}

const INVALID_CREDENTIALS_MESSAGE = "Email hoặc mật khẩu không đúng. Vui lòng thử lại.";
const RATE_LIMITED_MESSAGE = "Bạn đã thử đăng nhập quá nhiều lần. Vui lòng thử lại sau ít phút.";
const UNEXPECTED_MESSAGE = "Không thể đăng nhập lúc này. Vui lòng thử lại sau.";
const RATE_LIMITED_CODE = "rate_limited";

function readField(formData: FormData, name: string): string {
  const value = formData.get(name);
  return typeof value === "string" ? value : "";
}

function messageFor(error: AuthError): string {
  if (error instanceof CredentialsSignin) {
    return error.code === RATE_LIMITED_CODE ? RATE_LIMITED_MESSAGE : INVALID_CREDENTIALS_MESSAGE;
  }
  return UNEXPECTED_MESSAGE;
}

function buildRedirectTarget(callbackUrl: string | null): string {
  return callbackUrl
    ? `${POST_LOGIN_PATH}?callbackUrl=${encodeURIComponent(callbackUrl)}`
    : POST_LOGIN_PATH;
}

export async function signInAction(
  _previous: SignInState,
  formData: FormData,
): Promise<SignInState> {
  const parsed = signInSchema.safeParse({
    email: readField(formData, "email"),
    password: readField(formData, "password"),
  });

  if (!parsed.success) {
    return { error: INVALID_CREDENTIALS_MESSAGE };
  }

  const callbackUrl = sanitizeCallbackPath(readField(formData, "callbackUrl"));

  try {
    await signIn("credentials", { ...parsed.data, redirectTo: buildRedirectTarget(callbackUrl) });
  } catch (error) {
    if (error instanceof AuthError) {
      return { error: messageFor(error) };
    }
    // Successful sign-in redirects by throwing; anything else is not ours to swallow.
    throw error;
  }

  return { error: null };
}

export async function signOutAction(): Promise<void> {
  await signOut({ redirectTo: SIGN_IN_PATH });
}
