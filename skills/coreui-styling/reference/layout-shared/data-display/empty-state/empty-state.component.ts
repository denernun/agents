import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';

/**
 * Friendly empty state with optional action button.
 */
@Component({
  selector: 'app-empty-state',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="ds-empty">
      @if (icon()) {
        <div class="ds-empty__icon">
          <i [class]="icon()"></i>
        </div>
      }
      <h4 class="ds-empty__title">{{ title() }}</h4>
      @if (description()) {
        <p class="ds-empty__desc">{{ description() }}</p>
      }
      @if (actionLabel()) {
        <button type="button" class="btn btn-primary btn-sm mt-3" (click)="actionClick.emit()">
          {{ actionLabel() }}
        </button>
      }
    </div>
  `,
})
export class EmptyStateComponent {
  readonly title = input.required<string>();
  readonly description = input<string | undefined>(undefined);
  readonly icon = input<string>('fas fa-inbox');
  readonly actionLabel = input<string | undefined>(undefined);
  readonly actionClick = output<void>();
}
