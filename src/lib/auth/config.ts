import type { NextAuthConfig } from "next-auth";
import { isRole, SIGN_IN_PATH } from "./roles";
import "./types";

const SESSION_MAX_AGE_SECONDS = 8 * 60 * 60;

/**
 * Edge-safe half of the Auth.js config: no database, no Node-only imports.
 * The proxy uses it as is; src/lib/auth/auth.ts adds the Credentials provider.
 */
export const authConfig = {
  providers: [],
  pages: { signIn: SIGN_IN_PATH },
  session: { strategy: "jwt", maxAge: SESSION_MAX_AGE_SECONDS },
  callbacks: {
    jwt({ token, user }) {
      if (user) {
        token.sub = user.id;
        token.role = user.role;
      }
      return token;
    },
    session({ session, token }) {
      if (token.sub && isRole(token.role)) {
        session.user.id = token.sub;
        session.user.role = token.role;
      }
      return session;
    },
  },
} satisfies NextAuthConfig;
