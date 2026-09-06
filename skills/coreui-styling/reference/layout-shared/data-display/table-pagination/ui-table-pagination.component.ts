import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';
import { buildTablePageNumbers } from '../../tokens/table-tokens';

/**
 * Standard pagination footer for ds-table grids inside ui-card panels.
 */
@Component({
  selector: 'app-ui-table-pagination',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @if (totalRecords() > 0) {
      <div class="ds-panel__footer ds-panel__footer--pagination">
        <small class="ds-text-muted">{{ totalRecords() }} registro(s) — página {{ currentPage() }} de {{ totalPages() }}</small>
        @if (totalPages() > 1) {
          <nav aria-label="Paginação">
            <ul class="pagination justify-content-center mb-0">
              <li class="page-item" [class.disabled]="currentPage() === 1">
                <button type="button" class="page-link" (click)="onPageChange(currentPage() - 1)" [disabled]="currentPage() === 1">Anterior</button>
              </li>
              @for (page of visiblePages(); track page) {
                <li class="page-item" [class.active]="page === currentPage()">
                  <button type="button" class="page-link" (click)="onPageChange(page)">{{ page }}</button>
                </li>
              }
              <li class="page-item" [class.disabled]="currentPage() === totalPages()">
                <button type="button" class="page-link" (click)="onPageChange(currentPage() + 1)" [disabled]="currentPage() === totalPages()">Próximo</button>
              </li>
            </ul>
          </nav>
        }
      </div>
    }
  `,
})
export class UiTablePaginationComponent {
  readonly currentPage = input.required<number>();
  readonly totalPages = input.required<number>();
  readonly totalRecords = input.required<number>();
  readonly pageChange = output<number>();

  readonly visiblePages = computed((): number[] => buildTablePageNumbers(this.currentPage(), this.totalPages()));

  onPageChange(page: number): void {
    if (page < 1 || page > this.totalPages() || page === this.currentPage()) {
      return;
    }
    this.pageChange.emit(page);
  }
}
