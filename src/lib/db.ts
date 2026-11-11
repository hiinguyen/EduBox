import { PrismaPg } from "@prisma/adapter-pg";
import { PrismaClient } from "@/generated/prisma/client";
import { getEnv } from "@/lib/env";

function createClient(): PrismaClient {
  const adapter = new PrismaPg({ connectionString: getEnv().DATABASE_URL });
  return new PrismaClient({ adapter });
}

// Next dev hot reload re-evaluates modules; keep one client (and one pool) per process.
const globalForDb = globalThis as typeof globalThis & { edubox_prisma?: PrismaClient };

export const db: PrismaClient = globalForDb.edubox_prisma ?? createClient();

if (getEnv().NODE_ENV !== "production") {
  globalForDb.edubox_prisma = db;
}
