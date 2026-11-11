import { defineConfig } from "vitest/config";
import { sharedAlias } from "./src/test/alias";

export default defineConfig({
  resolve: { alias: sharedAlias },
  test: {
    include: ["src/**/*.test.ts", "src/**/*.test.tsx"],
    exclude: ["**/node_modules/**", "**/*.integration.test.ts"],
  },
});
