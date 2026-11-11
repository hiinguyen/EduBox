export type GuardFailureReason =
  "CROSS_ORIGIN" | "UNSUPPORTED_MEDIA_TYPE" | "PAYLOAD_TOO_LARGE" | "INVALID_JSON";

export interface GuardFailure {
  readonly ok: false;
  readonly reason: GuardFailureReason;
  /** HTTP status the route handler should answer with. */
  readonly status: 403 | 413 | 415 | 400;
}

export type GuardResult = { readonly ok: true } | GuardFailure;
export type JsonBodyResult = { readonly ok: true; readonly data: unknown } | GuardFailure;

export interface RequestGuardOptions {
  readonly maxBytes: number;
}

const JSON_CONTENT_TYPE = "application/json";
const CROSS_SITE_FETCH_VALUES: ReadonlySet<string> = new Set(["cross-site", "same-site"]);

function failure(reason: GuardFailureReason): GuardFailure {
  const status = {
    CROSS_ORIGIN: 403,
    UNSUPPORTED_MEDIA_TYPE: 415,
    PAYLOAD_TOO_LARGE: 413,
    INVALID_JSON: 400,
  } as const;
  return { ok: false, reason, status: status[reason] };
}

function expectedHost(request: Request): string | null {
  const host = request.headers.get("host");
  if (host) {
    return host;
  }
  try {
    return new URL(request.url).host;
  } catch {
    return null;
  }
}

function isSameOrigin(request: Request): boolean {
  const origin = request.headers.get("origin");

  if (origin === null) {
    // Browsers always send Origin on cross-origin POSTs; without it, trust Fetch Metadata.
    const site = request.headers.get("sec-fetch-site");
    return site === null || !CROSS_SITE_FETCH_VALUES.has(site);
  }

  try {
    return new URL(origin).host === expectedHost(request);
  } catch {
    return false;
  }
}

function isJsonContentType(request: Request): boolean {
  const type = request.headers.get("content-type")?.split(";")[0]?.trim().toLowerCase();
  return type === JSON_CONTENT_TYPE;
}

function declaredLength(request: Request): number | null {
  const raw = request.headers.get("content-length");
  if (raw === null) {
    return null;
  }
  const length = Number(raw);
  return Number.isSafeInteger(length) && length >= 0 ? length : Number.NaN;
}

/**
 * Cheap checks to run before touching the body: same origin, JSON content type, and a
 * declared Content-Length within `maxBytes`. Returns a typed result and never throws.
 */
export function assertSameOriginJson(request: Request, options: RequestGuardOptions): GuardResult {
  if (!isSameOrigin(request)) {
    return failure("CROSS_ORIGIN");
  }
  if (!isJsonContentType(request)) {
    return failure("UNSUPPORTED_MEDIA_TYPE");
  }

  const length = declaredLength(request);
  if (length !== null && !(length <= options.maxBytes)) {
    // NaN (malformed header) also lands here.
    return failure("PAYLOAD_TOO_LARGE");
  }
  return { ok: true };
}

async function readCapped(
  body: ReadableStream<Uint8Array>,
  maxBytes: number,
): Promise<Uint8Array | null> {
  const reader = body.getReader();
  const chunks: Uint8Array[] = [];
  let total = 0;

  try {
    for (;;) {
      const { done, value } = await reader.read();
      if (done) {
        break;
      }
      total += value.byteLength;
      if (total > maxBytes) {
        await reader.cancel();
        return null;
      }
      chunks.push(value);
    }
  } finally {
    reader.releaseLock();
  }

  const merged = new Uint8Array(total);
  let offset = 0;
  for (const chunk of chunks) {
    merged.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return merged;
}

/**
 * Reads and parses the JSON body while never buffering more than `maxBytes`, which also
 * covers chunked requests that carry no Content-Length.
 */
export async function readJsonBody(request: Request, maxBytes: number): Promise<JsonBodyResult> {
  const length = declaredLength(request);
  if (length !== null && !(length <= maxBytes)) {
    return failure("PAYLOAD_TOO_LARGE");
  }
  if (!request.body) {
    return failure("INVALID_JSON");
  }

  let bytes: Uint8Array | null;
  try {
    bytes = await readCapped(request.body, maxBytes);
  } catch {
    return failure("INVALID_JSON");
  }
  if (bytes === null) {
    return failure("PAYLOAD_TOO_LARGE");
  }

  try {
    return { ok: true, data: JSON.parse(new TextDecoder("utf-8", { fatal: true }).decode(bytes)) };
  } catch {
    return failure("INVALID_JSON");
  }
}
