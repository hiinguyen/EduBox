export interface Pagination {
  readonly page: number;
  readonly pageSize: number;
  readonly totalItems: number;
  readonly totalPages: number;
  /** 1-based position of the first and last item on this page; both 0 when empty. */
  readonly from: number;
  readonly to: number;
  readonly skip: number;
  readonly hasPrevious: boolean;
  readonly hasNext: boolean;
}

const FIRST_PAGE = 1;

/** Clamps an untrusted page number into 1..totalPages and derives the window math. */
export function paginate(totalItems: number, requestedPage: number, pageSize: number): Pagination {
  const totalPages = Math.max(FIRST_PAGE, Math.ceil(totalItems / pageSize));
  const page = Math.min(totalPages, Math.max(FIRST_PAGE, Math.trunc(requestedPage) || FIRST_PAGE));
  const skip = (page - 1) * pageSize;
  const itemsOnPage = Math.max(0, Math.min(pageSize, totalItems - skip));

  return {
    page,
    pageSize,
    totalItems,
    totalPages,
    from: itemsOnPage === 0 ? 0 : skip + 1,
    to: skip + itemsOnPage,
    skip,
    hasPrevious: page > FIRST_PAGE,
    hasNext: page < totalPages,
  };
}

/** Page (1-based) that contains the item with `itemsBefore` items ahead of it. */
export function pageOfIndex(itemsBefore: number, pageSize: number): number {
  return Math.floor(Math.max(0, itemsBefore) / pageSize) + FIRST_PAGE;
}
