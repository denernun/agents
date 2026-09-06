import { ChangeDetectionStrategy, Component, input } from '@angular/core';

/**
 * Page title block with optional subtitle, icon badge, and action slots.
 */
@Component({
  selector: 'app-page-header',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="ds-page-header d-flex flex-column flex-lg-row align-items-lg-start justify-content-lg-between gap-3">
      <div class="d-flex align-items-center gap-3">
        @if (icon()) {
          <div class="ds-page-header__icon">
            <i [class]="icon()"></i>
          </div>
        }
        <div>
          <h1 class="ds-page-header__title">{{ title() }}</h1>
          @if (subtitle()) {
            <p class="ds-page-header__subtitle">{{ subtitle() }}</p>
          }
        </div>
      </div>
      <ng-content select="[pageHeaderActions]" />
    </div>
  `,
})
export class PageHeaderComponent {
  readonly title = input.required<string>();
  readonly subtitle = input<string | undefined>(undefined);
  readonly icon = input<string | undefined>(undefined);
}
