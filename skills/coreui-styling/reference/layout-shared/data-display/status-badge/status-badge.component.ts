import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { UiAccentColor } from '../../tokens';

const BADGE_MODIFIER: Record<UiAccentColor, string> = {
  primary: 'ds-badge--primary',
  success: 'ds-badge--success',
  info: 'ds-badge--info',
  warning: 'ds-badge--warning',
  danger: 'ds-badge--danger',
  neutral: 'ds-badge--neutral',
};

/**
 * Standardized status pill for tables and lists.
 */
@Component({
  selector: 'app-status-badge',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: ` <span class="ds-badge" [class]="badgeClass()">{{ label() }}</span> `,
})
export class StatusBadgeComponent {
  readonly label = input.required<string>();
  readonly color = input<UiAccentColor>('neutral');

  readonly badgeClass = computed((): string => BADGE_MODIFIER[this.color()]);
}
