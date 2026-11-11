import type { ZodError } from "zod";

export type ActionErrorCode =
  | "UNAUTHENTICATED"
  | "FORBIDDEN"
  | "INVALID_INPUT"
  | "NOT_FOUND"
  | "RATE_LIMITED"
  | "CONFLICT"
  | "INTERNAL";

export interface ActionError {
  readonly code: ActionErrorCode;
  readonly message: string;
}

export type ActionResult<T> =
  { readonly ok: true; readonly data: T } | { readonly ok: false; readonly error: ActionError };

export const DEFAULT_ERROR_MESSAGES: Readonly<Record<ActionErrorCode, string>> = {
  UNAUTHENTICATED: "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.",
  FORBIDDEN: "Bạn không có quyền thực hiện thao tác này.",
  INVALID_INPUT: "Dữ liệu không hợp lệ. Vui lòng kiểm tra lại.",
  NOT_FOUND: "Không tìm thấy nội dung yêu cầu.",
  RATE_LIMITED: "Bạn thao tác quá nhanh. Vui lòng thử lại sau ít phút.",
  CONFLICT: "Nội dung đã thay đổi. Vui lòng tải lại trang và thử lại.",
  INTERNAL: "Đã xảy ra lỗi. Vui lòng thử lại sau.",
};

export function ok<T>(data: T): ActionResult<T> {
  return { ok: true, data };
}

export function fail(
  code: ActionErrorCode,
  message: string = DEFAULT_ERROR_MESSAGES[code],
): { readonly ok: false; readonly error: ActionError } {
  return { ok: false, error: { code, message } };
}

/** Maps the error branch of `requireRoleForAction` (structurally typed, so this stays pure). */
export function failFromAuth(authError: {
  readonly code: "UNAUTHENTICATED" | "FORBIDDEN";
  readonly message?: string;
}): { readonly ok: false; readonly error: ActionError } {
  return fail(authError.code, authError.message ?? DEFAULT_ERROR_MESSAGES[authError.code]);
}

/**
 * Vietnamese INVALID_INPUT. Names the first offending field (a schema path, never a value)
 * and does not echo the rejected input or Zod's English messages.
 */
export function failFromZod(error: ZodError): { readonly ok: false; readonly error: ActionError } {
  const field = error.issues[0]?.path.map(String).join(".");
  const base = DEFAULT_ERROR_MESSAGES.INVALID_INPUT;
  return fail("INVALID_INPUT", field ? `${base} (trường: ${field})` : base);
}
