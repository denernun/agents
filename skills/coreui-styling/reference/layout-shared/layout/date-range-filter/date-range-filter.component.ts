import { ChangeDetectionStrategy, Component, OnInit, input, output } from '@angular/core';
import { FormsModule } from '@angular/forms';
import { BsDatepickerModule } from 'ngx-bootstrap/datepicker';
import { BsDropdownModule } from 'ngx-bootstrap/dropdown';
import dayjs from 'dayjs';

/**
 * Named quick-select ranges offered by the shortcuts dropdown.
 */
export type DateRangePreset = 'today' | 'last7' | 'last30' | 'month' | 'lastMonth';

/**
 * Computes the [start, end] Date pair for a named preset.
 * `start` is the beginning of its first day, `end` the end of its last day.
 */
export function computeDateRangePreset(preset: DateRangePreset): readonly [Date, Date] {
  switch (preset) {
    case 'today':
      return [dayjs().startOf('day').toDate(), dayjs().endOf('day').toDate()];
    case 'last7':
      return [dayjs().subtract(7, 'day').startOf('day').toDate(), dayjs().endOf('day').toDate()];
    case 'last30':
      return [dayjs().subtract(30, 'day').startOf('day').toDate(), dayjs().endOf('day').toDate()];
    case 'month': {
      const start = dayjs().startOf('month').toDate();
      return [start, dayjs(start).endOf('month').toDate()];
    }
    case 'lastMonth': {
      const start = dayjs().subtract(1, 'month').startOf('month').toDate();
      return [start, dayjs(start).endOf('month').toDate()];
    }
  }
}

function rangeKey(start: Date, end: Date): string {
  // Calendar-day identity — ngx-bootstrap may rewrite the same range with
  // different millisecond precision, which must not count as a new emit.
  const startDay = `${start.getFullYear()}-${start.getMonth()}-${start.getDate()}`;
  const endDay = `${end.getFullYear()}-${end.getMonth()}-${end.getDate()}`;
  return `${startDay}:${endDay}`;
}

/**
 * Date-range filter used on every dashboard/list page that filters by
 * period: a quick-select shortcuts dropdown (Hoje / 7 dias / 30 dias / Mês
 * atual / Mês anterior) plus an `ngx-bootstrap` `bsDaterangepicker` input for
 * a custom range. Wraps the exact pattern already duplicated inline across
 * pages — see design-system.md §"ngx-bootstrap suite" for the full contract
 * (global `BsDatepickerConfig`/`BsDaterangepickerConfig`, `containerClass:
 * 'ds-datepicker'`, locale registration).
 *
 * Emits only when the range actually changes. Programmatic preset/model writes
 * suppress the ngx-bootstrap `bsValueChange` echo that would otherwise storm
 * the parent with duplicate loads (and trip API rate limits).
 */
@Component({
  selector: 'app-date-range-filter',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [FormsModule, BsDatepickerModule, BsDropdownModule],
  template: `
    <div class="input-group">
      <div class="input-group-prepend">
        <div class="btn-group" dropdown>
          <button dropdownToggle type="button" class="btn btn-outline-secondary dropdown-toggle" [attr.aria-label]="shortcutsLabel()">
            <i class="fas fa-bars" aria-hidden="true"></i>
          </button>
          <ul *dropdownMenu class="dropdown-menu ds-dropdown__menu" role="menu">
            <li role="menuitem"><button class="dropdown-item" type="button" (click)="selectPreset('today')">Hoje</button></li>
            <li class="divider dropdown-divider"></li>
            <li role="menuitem"><button class="dropdown-item" type="button" (click)="selectPreset('last7')">Últimos 7 dias</button></li>
            <li role="menuitem"><button class="dropdown-item" type="button" (click)="selectPreset('last30')">Últimos 30 dias</button></li>
            <li class="divider dropdown-divider"></li>
            <li role="menuitem"><button class="dropdown-item" type="button" (click)="selectPreset('month')">Mês atual</button></li>
            <li role="menuitem"><button class="dropdown-item" type="button" (click)="selectPreset('lastMonth')">Mês anterior</button></li>
          </ul>
        </div>
      </div>
      <input
        class="form-control ds-form-control"
        bsDaterangepicker
        containerClass="ds-datepicker"
        [(ngModel)]="rangeValue"
        [ngModelOptions]="{ standalone: true }"
        (bsValueChange)="onPickerChange($event)"
        [attr.aria-label]="inputLabel()"
      />
    </div>
  `,
})
export class DateRangeFilterComponent implements OnInit {
  readonly initialPreset = input<DateRangePreset>('today');
  readonly shortcutsLabel = input<string>('Atalhos de período');
  readonly inputLabel = input<string>('Período');
  readonly rangeChange = output<readonly [Date, Date]>();

  protected rangeValue: Date[] = [];

  /** Ignores picker echoes while we write `rangeValue` ourselves. */
  private suppressPickerEmit = false;
  private lastEmittedKey: string | null = null;

  public ngOnInit(): void {
    this.applyPreset(this.initialPreset());
  }

  protected selectPreset(preset: DateRangePreset): void {
    this.applyPreset(preset);
  }

  protected onPickerChange(dates: Date[] | undefined): void {
    if (this.suppressPickerEmit) {
      return;
    }
    if (!dates?.[0] || !dates?.[1]) {
      return;
    }
    if (rangeKey(dates[0], dates[1]) === this.lastEmittedKey) {
      return;
    }
    this.suppressPickerEmit = true;
    this.rangeValue = dates;
    this.emitIfChanged();
    setTimeout(() => {
      this.suppressPickerEmit = false;
    });
  }

  private applyPreset(preset: DateRangePreset): void {
    this.suppressPickerEmit = true;
    this.rangeValue = [...computeDateRangePreset(preset)];
    this.emitIfChanged();
    // ngx-bootstrap may echo `bsValueChange` after the model write settles.
    setTimeout(() => {
      this.suppressPickerEmit = false;
    });
  }

  private emitIfChanged(): void {
    const [start, end] = this.rangeValue;
    if (!start || !end) {
      return;
    }
    const key = rangeKey(start, end);
    if (key === this.lastEmittedKey) {
      return;
    }
    this.lastEmittedKey = key;
    this.rangeChange.emit([start, end]);
  }
}
