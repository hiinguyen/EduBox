import "dotenv/config";
import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "../src/generated/prisma/client";
import { seedAssessments } from "./seed-lib/assessments";
import { seedLearning } from "./seed-lib/learning";
import { seedParentPortal } from "./seed-lib/parent";
import { seedPeople } from "./seed-lib/people";

/** Dev-only password shared by every demo account. Only used when the seed guard passes. */
const DEV_DEMO_PASSWORD = "Demo@12345";
const LOCAL_HOSTS: ReadonlySet<string> = new Set(["localhost", "127.0.0.1", "::1", "[::1]"]);

function resolveDemoPassword(): string {
  const fromEnv = process.env.SEED_DEMO_PASSWORD;
  return fromEnv && fromEnv.length > 0 ? fromEnv : DEV_DEMO_PASSWORD;
}

function hostOf(connectionString: string): string {
  try {
    return new URL(connectionString).hostname.toLowerCase();
  } catch {
    throw new Error("DATABASE_URL is not a valid connection string.");
  }
}

/**
 * Demo data uses a well-known password, so seeding needs an explicit opt-in AND a local
 * database. Only the host is ever reported, never the credentials.
 */
function assertSeedAllowed(connectionString: string): void {
  if (process.env.NODE_ENV === "production") {
    throw new Error("Refusing to seed demo data when NODE_ENV=production.");
  }
  if (process.env.ALLOW_DEMO_SEED !== "1") {
    throw new Error(
      "Refusing to seed demo data: set ALLOW_DEMO_SEED=1 to opt in (local use only).",
    );
  }
  const host = hostOf(connectionString);
  if (!LOCAL_HOSTS.has(host)) {
    throw new Error(`Refusing to seed demo data into a non-local database host (${host}).`);
  }
}

async function main(): Promise<void> {
  const connectionString = process.env.DATABASE_URL;
  if (!connectionString) {
    throw new Error("DATABASE_URL is not set. Copy .env.example to .env first.");
  }

  assertSeedAllowed(connectionString);

  const db = new PrismaClient({ adapter: new PrismaPg({ connectionString }) });

  try {
    const context = await seedPeople(db, resolveDemoPassword());
    await seedLearning(context);
    await seedAssessments(context);
    await seedParentPortal(context);
  } finally {
    await db.$disconnect();
  }
}

main().catch((error: unknown) => {
  process.stderr.write(`Seed failed: ${error instanceof Error ? error.message : String(error)}\n`);
  process.exitCode = 1;
});
