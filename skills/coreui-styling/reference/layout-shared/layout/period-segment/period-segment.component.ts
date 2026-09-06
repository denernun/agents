import { ChangeDetectionStrategy, Component, input, output } from '@angular/core';

export interface PeriodSegmentOption {
  readonly id: string;
  readonly label: string;
}

const DEFAULT_PERIOD_OPTIONS: readonly PeriodSegmentOption[] = [
  { id: 'day', label: 'Diário' },
  { id: 'week', label: 'Semana' },
  { id: 'month', label: 'Mês' },
  { id: 'year', label: 'Ano' },
] as const;

/**
 * Compact pill group for switching dashboard time ranges.
 */
@Component({
  selector: 'app-period-segment',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="ds-segment" role="group" [attr.aria-label]="ariaLabel()">
      @for (option of options(); track option.id) {
        <button type="button" class="ds-segment__btn" [class.ds-segment__btn--active]="option.id === active()" (click)="changed.emit(option.id)">
          {{ option.label }}
        </button>
      }
    </div>
  `,
})
export class PeriodSegmentComponent {
  readonly options = input<readonly PeriodSegmentOption[]>(DEFAULT_PERIOD_OPTIONS);
  readonly active = input<string>('day');
  readonly ariaLabel = input<string>('Período');
  readonly changed = output<string>();
}
