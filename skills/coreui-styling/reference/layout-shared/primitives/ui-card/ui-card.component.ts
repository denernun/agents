import { ChangeDetectionStrategy, Component, input } from '@angular/core';

/**
 * Base surface card with optional titled header — uses ds-panel SCSS.
 */
@Component({
  selector: 'app-ui-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'd-block h-100',
  },
  template: `
    <div class="ds-panel">
      @if (title()) {
        <div class="ds-panel__header">
          <div class="ds-panel__heading">
            <h3 class="ds-panel__title">
              @if (icon()) {
                <span class="ds-panel__title-icon"><i [class]="icon()"></i></span>
              }
              {{ title() }}
            </h3>
            @if (subtitle()) {
              <p class="ds-panel__subtitle">{{ subtitle() }}</p>
            }
          </div>
          <ng-content select="[uiCardActions]" />
        </div>
      }
      <div class="ds-panel__body" [class.ds-panel__body--flush]="noPadding()">
        <ng-content />
      </div>
      <ng-content select="[uiCardFooter]" />
    </div>
  `,
})
export class UiCardComponent {
  readonly title = input<string | undefined>(undefined);
  readonly subtitle = input<string | undefined>(undefined);
  readonly icon = input<string | undefined>(undefined);
  readonly noPadding = input<boolean>(false);
}
