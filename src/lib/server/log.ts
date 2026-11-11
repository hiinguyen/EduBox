import "server-only";

type LogContext = Readonly<Record<string, string | number>>;

const UNKNOWN_ERROR_NAME = "UnknownError";

function describeError(error: unknown): { name: string; code?: string } {
  if (!(error instanceof Error)) {
    return { name: UNKNOWN_ERROR_NAME };
  }
  const code = (error as { code?: unknown }).code;
  return typeof code === "string" ? { name: error.name, code } : { name: error.name };
}

/**
 * The single server-side error logger. Logs the scope, error name, error code and caller
 * supplied ids only: never `error.message` (it can carry SQL, answers or names).
 */
export function logServerError(scope: string, error: unknown, context: LogContext = {}): void {
  const entry = { scope, ...describeError(error), ...context };
  process.stderr.write(`${JSON.stringify(entry)}\n`);
}
