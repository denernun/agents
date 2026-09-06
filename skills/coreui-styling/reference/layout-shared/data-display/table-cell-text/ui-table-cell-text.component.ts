import { ChangeDetectionStrategy, Component, computed, input } from '@angular/core';

/**
 * Single-line table cell text with ellipsis and native title tooltip.
 */
@Component({
  selector: 'app-ui-table-cell-text',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `<span class="ds-table__truncate" [class.fw-medium]="emphasis()" [title]="resolvedTooltip()">{{ value() }}</span>`,
})
export class UiTableCellTextComponent {
  readonly value = input.required<string>();
  readonly tooltip = input<string | undefined>(undefined);
  readonly emphasis = input<boolean>(false);

  readonly resolvedTooltip = computed((): string => this.tooltip() ?? this.value());
}
