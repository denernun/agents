/** Default page size for dashboard data grids. */
export const DS_TABLE_PAGE_SIZE = 10;

/** Builds a sliding window of page numbers for pagination controls. */
export function buildTablePageNumbers(currentPage: number, totalPages: number, maxPagesToShow: number = 5): number[] {
  if (totalPages <= 0) {
    return [];
  }
  let start: number = Math.max(1, currentPage - Math.floor(maxPagesToShow / 2));
  let end: number = start + maxPagesToShow - 1;
  if (end > totalPages) {
    end = totalPages;
    start = Math.max(1, end - maxPagesToShow + 1);
  }
  const pages: number[] = [];
  for (let i: number = start; i <= end; i++) {
    pages.push(i);
  }
  return pages;
}
