const TEST_SUFFIX = "_test";

/**
 * Derives the integration-test database URL from DATABASE_URL by suffixing the database name.
 * An explicit TEST_DATABASE_URL wins.
 */
export function resolveTestDatabaseUrl(env: Readonly<Record<string, string | undefined>>): string {
  if (env.TEST_DATABASE_URL) {
    return env.TEST_DATABASE_URL;
  }
  if (!env.DATABASE_URL) {
    throw new Error("DATABASE_URL is not set. Copy .env.example to .env first.");
  }

  const url = new URL(env.DATABASE_URL);
  const name = url.pathname.replace(/^\//, "");
  url.pathname = `/${name.endsWith(TEST_SUFFIX) ? name : `${name}${TEST_SUFFIX}`}`;
  return url.toString();
}

export function databaseNameOf(connectionString: string): string {
  return new URL(connectionString).pathname.replace(/^\//, "");
}

export function withDatabase(connectionString: string, database: string): string {
  const url = new URL(connectionString);
  url.pathname = `/${database}`;
  return url.toString();
}
