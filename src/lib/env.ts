import { z } from "zod";

const MIN_AUTH_SECRET_LENGTH = 32;

const optionalNonEmpty = z
  .string()
  .optional()
  .transform((value) => (value && value.length > 0 ? value : undefined));

const HTTPS_PROTOCOL = "https:";
const LOOPBACK_HOSTNAMES: ReadonlySet<string> = new Set(["localhost", "127.0.0.1", "[::1]"]);

/** Plain http is only tolerated on loopback, where nothing can sit on the wire. */
function isSecureOrLoopbackUrl(value: string): boolean {
  const url = new URL(value);
  return url.protocol === HTTPS_PROTOCOL || LOOPBACK_HOSTNAMES.has(url.hostname);
}

const baseSchema = z.object({
  NODE_ENV: z.enum(["development", "test", "production"]).default("development"),
  DATABASE_URL: z.string().min(1).startsWith("postgresql://"),
  AUTH_SECRET: z.string().min(MIN_AUTH_SECRET_LENGTH),
  AUTH_URL: z.url().optional(),
  TRUSTED_PROXY_HOPS: z.coerce.number().int().min(0).default(0),
  OPENCODE_API_KEY: optionalNonEmpty,
  OPENCODE_BASE_URL: optionalNonEmpty.pipe(z.url().optional()),
  AI_MODEL: optionalNonEmpty,
});

const envSchema = baseSchema.superRefine((env, context) => {
  if (env.NODE_ENV !== "production") {
    return;
  }
  for (const name of ["AUTH_URL", "OPENCODE_BASE_URL"] as const) {
    const value = env[name];
    if (value !== undefined && !isSecureOrLoopbackUrl(value)) {
      context.addIssue({
        code: "custom",
        path: [name],
        message: "must use https in production (http is only allowed on localhost)",
      });
    }
  }
});

export type Env = z.infer<typeof envSchema>;

export class EnvError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "EnvError";
  }
}

/**
 * Validates a raw environment. Only variable names and rule descriptions end up in
 * the message, never the received values, so secrets cannot leak into logs.
 */
export function parseEnv(source: Readonly<Record<string, string | undefined>>): Env {
  const result = envSchema.safeParse(source);

  if (result.success) {
    return result.data;
  }

  const problems = result.error.issues.map(
    (issue) => `- ${issue.path.join(".") || "(root)"}: ${issue.message}`,
  );
  throw new EnvError(
    `Invalid environment configuration. Fix .env (see .env.example):\n${problems.join("\n")}`,
  );
}

let cachedEnv: Env | undefined;

/** Parses `process.env` once and reuses the typed result. Throws EnvError when invalid. */
export function getEnv(): Env {
  cachedEnv ??= parseEnv(process.env);
  return cachedEnv;
}
