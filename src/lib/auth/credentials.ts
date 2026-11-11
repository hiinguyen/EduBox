import "server-only";
import type { Role } from "@/generated/prisma/enums";
import { db } from "@/lib/db";
import { burnVerifyTime, verifyPassword } from "./password";
import { signInSchema } from "./schemas";

export interface VerifiedUser {
  readonly id: string;
  readonly email: string;
  readonly name: string;
  readonly role: Role;
}

/**
 * The only place that reads Credential.passwordHash.
 * Returns null for malformed input, unknown email and wrong password alike, and spends
 * a hash verification in every branch so response time does not reveal which one it was.
 */
export async function verifyCredentials(rawInput: unknown): Promise<VerifiedUser | null> {
  const parsed = signInSchema.safeParse(rawInput);

  if (!parsed.success) {
    await burnVerifyTime("invalid-input");
    return null;
  }

  const { email, password } = parsed.data;
  const user = await db.user.findUnique({
    where: { email },
    select: {
      id: true,
      email: true,
      name: true,
      role: true,
      credential: { select: { passwordHash: true } },
    },
  });

  if (!user?.credential) {
    await burnVerifyTime(password);
    return null;
  }

  const isValid = await verifyPassword(user.credential.passwordHash, password);

  return isValid ? { id: user.id, email: user.email, name: user.name, role: user.role } : null;
}
