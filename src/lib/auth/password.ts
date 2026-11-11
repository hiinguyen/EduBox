import { hash, verify } from "@node-rs/argon2";

// OWASP argon2id baseline: 19 MiB memory, 2 iterations, 1 lane.
const ARGON2_OPTIONS = {
  memoryCost: 19_456,
  timeCost: 2,
  parallelism: 1,
} as const;

export function hashPassword(plain: string): Promise<string> {
  return hash(plain, ARGON2_OPTIONS);
}

export async function verifyPassword(storedHash: string, plain: string): Promise<boolean> {
  try {
    return await verify(storedHash, plain);
  } catch {
    // A malformed stored hash must behave exactly like a wrong password.
    return false;
  }
}

let dummyHash: Promise<string> | undefined;

/** Verifies against a throwaway hash so unknown accounts cost the same time as wrong passwords. */
export async function burnVerifyTime(plain: string): Promise<void> {
  dummyHash ??= hashPassword("edubox-timing-equalizer");
  await verifyPassword(await dummyHash, plain);
}
