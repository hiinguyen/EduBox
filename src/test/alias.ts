import { fileURLToPath } from "node:url";

export const sharedAlias = {
  "@": fileURLToPath(new URL("..", import.meta.url)),
  "server-only": fileURLToPath(new URL("./server-only-stub.ts", import.meta.url)),
};
