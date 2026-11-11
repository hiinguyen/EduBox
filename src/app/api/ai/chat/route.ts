import { NextResponse } from "next/server";
import { requireRoleForAction } from "@/lib/auth/session";
import { sendTutorMessage } from "@/lib/hoc-tap/chat-service";
import type { ChatResult } from "@/lib/hoc-tap/chat-service";
import { CHAT_MAX_BODY_BYTES } from "@/lib/hoc-tap/constants";
import { MS_PER_SECOND } from "@/lib/format/time";
import { fail, failFromAuth } from "@/lib/server/action-result";
import type { ActionErrorCode } from "@/lib/server/action-result";
import { assertSameOriginJson, readJsonBody } from "@/lib/server/request-guard";
import type { GuardFailure, GuardFailureReason } from "@/lib/server/request-guard";

const STATUS_BY_CODE: Readonly<Record<ActionErrorCode, number>> = {
  INVALID_INPUT: 400,
  UNAUTHENTICATED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  RATE_LIMITED: 429,
  INTERNAL: 500,
};

const CODE_BY_GUARD_REASON: Readonly<Record<GuardFailureReason, ActionErrorCode>> = {
  CROSS_ORIGIN: "FORBIDDEN",
  UNSUPPORTED_MEDIA_TYPE: "INVALID_INPUT",
  PAYLOAD_TOO_LARGE: "INVALID_INPUT",
  INVALID_JSON: "INVALID_INPUT",
};

function respond(result: ChatResult): NextResponse {
  if (result.ok) return NextResponse.json(result);

  const { ok, error, retryAfterMs } = result;
  const headers =
    error.code === "RATE_LIMITED" && retryAfterMs !== undefined
      ? { "Retry-After": String(Math.max(1, Math.ceil(retryAfterMs / MS_PER_SECOND))) }
      : undefined;
  return NextResponse.json({ ok, error }, { status: STATUS_BY_CODE[error.code], headers });
}

function respondToGuardFailure(failure: GuardFailure): NextResponse {
  return NextResponse.json(fail(CODE_BY_GUARD_REASON[failure.reason]), { status: failure.status });
}

export async function POST(request: Request): Promise<NextResponse> {
  const guard = assertSameOriginJson(request, { maxBytes: CHAT_MAX_BODY_BYTES });
  if (!guard.ok) return respondToGuardFailure(guard);

  const auth = await requireRoleForAction("STUDENT");
  if (!auth.ok) return respond(failFromAuth(auth.error));

  const body = await readJsonBody(request, CHAT_MAX_BODY_BYTES);
  if (!body.ok) return respondToGuardFailure(body);

  return respond(await sendTutorMessage(auth.user, body.data));
}
