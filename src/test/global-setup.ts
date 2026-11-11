import { execFileSync } from "node:child_process";
import { Client } from "pg";
import { databaseNameOf, resolveTestDatabaseUrl, withDatabase } from "./test-database";

const ADMIN_DATABASE = "postgres";
const SAFE_NAME = /^[a-z0-9_]+$/;

async function ensureDatabase(testUrl: string): Promise<void> {
  const name = databaseNameOf(testUrl);

  if (!SAFE_NAME.test(name)) {
    throw new Error(`Refusing to create test database with unsafe name: ${name}`);
  }

  const admin = new Client({ connectionString: withDatabase(testUrl, ADMIN_DATABASE) });
  await admin.connect();
  try {
    const found = await admin.query("SELECT 1 FROM pg_database WHERE datname = $1", [name]);
    if (found.rowCount === 0) {
      await admin.query(`CREATE DATABASE "${name}"`);
    }
  } finally {
    await admin.end();
  }
}

/** Creates the `<db>_test` database if needed and applies all migrations to it. */
export default async function setup(): Promise<void> {
  const testUrl = resolveTestDatabaseUrl(process.env);

  await ensureDatabase(testUrl);
  execFileSync("pnpm", ["exec", "prisma", "migrate", "deploy"], {
    env: { ...process.env, DATABASE_URL: testUrl },
    stdio: "pipe",
  });
}
