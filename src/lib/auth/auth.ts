import "server-only";
import NextAuth, { CredentialsSignin } from "next-auth";
import Credentials from "next-auth/providers/credentials";
import { authConfig } from "./config";
import { verifyCredentials } from "./credentials";
import { signInSchema } from "./schemas";
import { isSignInBlocked } from "./sign-in-limits";

export class RateLimitedSignIn extends CredentialsSignin {
  code = "rate_limited";
}

export const { handlers, auth, signIn, signOut } = NextAuth({
  ...authConfig,
  providers: [
    Credentials({
      credentials: { email: {}, password: {} },
      // Runs for every sign-in path (server action and /api/auth/callback/credentials alike).
      async authorize(rawCredentials, request) {
        const parsed = signInSchema.safeParse(rawCredentials);

        if (await isSignInBlocked(request, parsed.success ? parsed.data.email : null)) {
          throw new RateLimitedSignIn();
        }

        return verifyCredentials(rawCredentials);
      },
    }),
  ],
});
