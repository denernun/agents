import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import type { UiAccentColor } from '../../tokens';

/**
 * Compact insight tile used in dashboard alert strips.
 */
@Component({
  selector: 'app-insight-alert',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="ds-insight-alert" [class]="'ds-insight-alert--' + tone()">
      <div class="ds-insight-alert__icon">
        <i [class]="icon()"></i>
      </div>
      <div class="mw-100">
        <p class="ds-insight-alert__title">{{ title() }}</p>
        <p class="ds-insight-alert__text">{{ text() }}</p>
        @if (actionLabel()) {
          <span class="ds-insight-alert__link">{{ actionLabel() }}</span>
        }
      </div>
    </div>
  `,
})
export class InsightAlertComponent {
  readonly title = input.required<string>();
  readonly text = input.required<string>();
  readonly icon = input<string>('fas fa-circle-info');
  readonly tone = input<UiAccentColor>('info');
  readonly actionLabel = input<string | undefined>(undefined);
}
