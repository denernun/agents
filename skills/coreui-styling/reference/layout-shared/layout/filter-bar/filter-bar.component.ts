import { ChangeDetectionStrategy, Component, input } from '@angular/core';

/**
 * Responsive wrapper for filter controls with titled header bar.
 */
@Component({
  selector: 'app-filter-bar',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="ds-panel ds-filter-panel mb-4">
      <div class="ds-panel__header">
        <h3 class="ds-panel__title">
          <span class="ds-panel__title-icon"><i class="fas fa-filter"></i></span>
          {{ label() }}
        </h3>
        @if (loading()) {
          <span class="spinner-border spinner-border-sm text-secondary" role="status" aria-label="Carregando"></span>
        }
      </div>
      <div class="ds-panel__body">
        <div class="row g-3">
          <ng-content />
        </div>
      </div>
    </div>
  `,
})
export class FilterBarComponent {
  readonly label = input<string>('Filtros');
  readonly loading = input<boolean>(false);
}
