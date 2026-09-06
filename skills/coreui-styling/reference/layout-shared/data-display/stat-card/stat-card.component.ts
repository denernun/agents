import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';
import { UiSkeletonComponent } from '../../primitives/ui-skeleton';
import { UiAccentColor } from '../../tokens';

export type StatCardVariant = 'default' | 'hero' | 'metric';

const STAT_CARD_MODIFIER: Record<UiAccentColor, string> = {
  primary: 'ds-stat-card--primary',
  success: 'ds-stat-card--success',
  info: 'ds-stat-card--info',
  warning: 'ds-stat-card--warning',
  danger: 'ds-stat-card--danger',
  neutral: 'ds-stat-card--neutral',
};

/**
 * KPI card with accent icon, value, trend chip and optional sparkline.
 * `hero` fills the card with the accent color; `metric` is a compact centered tile with a left border.
 */
@Component({
  selector: 'app-stat-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [UiSkeletonComponent],
  host: { class: 'd-flex flex-column h-100' },
  template: `
    @if (loading()) {
      <div class="h-100">
        <app-ui-skeleton variant="card" />
      </div>
    } @else if (variant() === 'hero') {
      <div [class]="cardClass()">
        <div>
          <p class="ds-stat-card__label">{{ title() }}</p>
          <p class="ds-stat-card__value">{{ value() }}</p>
        </div>
        @if (icon()) {
          <i [class]="'ds-stat-card__watermark ' + icon()" aria-hidden="true"></i>
        }
      </div>
    } @else if (variant() === 'metric') {
      <div [class]="cardClass()">
        @if (icon()) {
          <div class="ds-stat-card__icon">
            <i [class]="icon()"></i>
          </div>
        }
        <p class="ds-stat-card__label">{{ title() }}</p>
        <p class="ds-stat-card__value">{{ value() }}</p>
      </div>
    } @else {
      <div [class]="cardClass()">
        <div class="ds-stat-card__top">
          @if (icon()) {
            <div class="ds-stat-card__icon">
              <i [class]="icon()"></i>
            </div>
          } @else {
            <span></span>
          }
          @if (variation() !== undefined) {
            <span class="ds-stat-card__variation" [class]="variationClass()">
              @if (variation()! >= 0) {
                <i class="fas fa-arrow-up"></i>
              } @else {
                <i class="fas fa-arrow-down"></i>
              }
              {{ variationLabel() ?? formattedVariation() }}
            </span>
          }
        </div>
        <p class="ds-stat-card__label">{{ title() }}</p>
        <p class="ds-stat-card__value">{{ value() }}</p>
        @if (subtitle()) {
          <p class="ds-stat-card__subtitle">{{ subtitle() }}</p>
        }
        @if (sparkPoints()) {
          <svg class="ds-stat-card__spark" viewBox="0 0 100 32" preserveAspectRatio="none" aria-hidden="true">
            <polyline fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" [attr.points]="sparkPoints()" />
          </svg>
        }
      </div>
    }
  `,
})
export class StatCardComponent {
  readonly title = input.required<string>();
  readonly value = input.required<string>();
  readonly subtitle = input<string | undefined>(undefined);
  readonly variation = input<number | undefined>(undefined);
  readonly variationLabel = input<string | undefined>(undefined);
  readonly icon = input<string | undefined>(undefined);
  readonly color = input<UiAccentColor>('primary');
  readonly variant = input<StatCardVariant>('default');
  readonly loading = input<boolean>(false);
  readonly sparkline = input<readonly number[]>([]);

  readonly cardClass = computed((): string => {
    const variant: StatCardVariant = this.variant();
    const variantClass: string = variant === 'default' ? '' : `ds-stat-card--${variant}`;
    return ['ds-stat-card', STAT_CARD_MODIFIER[this.color()], variantClass].filter((item: string) => item.length > 0).join(' ');
  });

  readonly variationClass = computed((): string => {
    const value: number | undefined = this.variation();
    if (value === undefined) {
      return '';
    }
    return value >= 0 ? 'ds-stat-card__variation--up' : 'ds-stat-card__variation--down';
  });

  readonly formattedVariation = computed((): string => {
    const value: number | undefined = this.variation();
    if (value === undefined) {
      return '';
    }
    return `${Math.abs(value).toFixed(2)}%`;
  });

  readonly sparkPoints = computed((): string | null => {
    const values: readonly number[] = this.sparkline();
    if (values.length < 2) {
      return null;
    }
    const min: number = Math.min(...values);
    const max: number = Math.max(...values);
    const span: number = max - min || 1;
    return values
      .map((point: number, index: number): string => {
        const x: number = (index / (values.length - 1)) * 100;
        const y: number = 28 - ((point - min) / span) * 24;
        return `${x.toFixed(2)},${y.toFixed(2)}`;
      })
      .join(' ');
  });
}
