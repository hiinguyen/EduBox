import { z } from "zod";
import { MAX_ID_LENGTH, QUERY_KEYS, WORKSPACE_PATH } from "./constants";

export type RawSearchParams = Readonly<Record<string, string | readonly string[] | undefined>>;

/** What the URL asks for. Ids are untrusted: they are only ever used inside scoped queries. */
export interface WorkspaceQuery {
  readonly classId?: string | undefined;
  readonly assessmentId?: string | undefined;
  readonly submissionId?: string | undefined;
  readonly page?: number | undefined;
  readonly lecturePage?: number | undefined;
}

const idSchema = z.string().trim().min(1).max(MAX_ID_LENGTH).optional().catch(undefined);
const pageSchema = z.coerce.number().int().min(1).optional().catch(undefined);

const querySchema = z.object({
  classId: idSchema,
  assessmentId: idSchema,
  submissionId: idSchema,
  page: pageSchema,
  lecturePage: pageSchema,
});

function firstValue(value: string | readonly string[] | undefined): string | undefined {
  return typeof value === "string" ? value : value?.[0];
}

export function parseWorkspaceQuery(params: RawSearchParams): WorkspaceQuery {
  return querySchema.parse({
    classId: firstValue(params[QUERY_KEYS.classId]),
    assessmentId: firstValue(params[QUERY_KEYS.assessmentId]),
    submissionId: firstValue(params[QUERY_KEYS.submissionId]),
    page: firstValue(params[QUERY_KEYS.page]),
    lecturePage: firstValue(params[QUERY_KEYS.lecturePage]),
  });
}

/** The resolved state a link must preserve; undefined fields are left out of the URL. */
export interface HrefState {
  readonly classId?: string | undefined;
  readonly assessmentId?: string | null | undefined;
  readonly submissionId?: string | undefined;
  readonly page?: number | undefined;
  readonly lecturePage?: number | undefined;
}

const FIRST_PAGE = 1;

export function buildWorkspaceHref(state: HrefState): string {
  const params = new URLSearchParams();
  if (state.classId) params.set(QUERY_KEYS.classId, state.classId);
  if (state.assessmentId) params.set(QUERY_KEYS.assessmentId, state.assessmentId);
  if (state.page !== undefined && state.page > FIRST_PAGE) {
    params.set(QUERY_KEYS.page, String(state.page));
  }
  if (state.submissionId) params.set(QUERY_KEYS.submissionId, state.submissionId);
  if (state.lecturePage !== undefined && state.lecturePage > FIRST_PAGE) {
    params.set(QUERY_KEYS.lecturePage, String(state.lecturePage));
  }
  const search = params.toString();
  return search === "" ? WORKSPACE_PATH : `${WORKSPACE_PATH}?${search}`;
}
