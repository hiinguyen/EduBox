import "dotenv/config";
import { defineConfig } from "vitest/config";
import { sharedAlias } from "./src/test/alias";
import { resolveTestDatabaseUrl } from "./src/test/test-database";

const TEST_TIMEOUT_MS = 30_000;

/** Integration tests run against a dedicated `<db>_test` database, never the dev data. */
export default defineConfig({
  resolve: { alias: sharedAlias },
  test: {
    include: ["src/**/*.integration.test.ts"],
    globalSetup: ["./src/test/global-setup.ts"],
    env: { DATABASE_URL: resolveTestDatabaseUrl(process.env) },
    // Test files share one database, so they run one at a time. Suites that call
    // resetDatabase() (src/test/world.ts) depend on this; prefer createTaggedWorld().
    fileParallelism: false,
    testTimeout: TEST_TIMEOUT_MS,
    hookTimeout: TEST_TIMEOUT_MS,
  },
});
