import { ChangeDetectionStrategy, Component, input } from '@angular/core';

/**
 * Responsive data table wrapper applying ds-table styles consistently.
 */
@Component({
  selector: 'app-ui-data-table',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="table-responsive" [class.ds-table__viewport--fixed-rows]="fixedHeight()" [style.--ds-table-fixed-rows]="fixedHeight() ? fixedRowCount() : null">
      <table class="ds-table table table-sm mb-0" [class.ds-table--fixed-rows]="fixedRows()" [class.align-middle]="alignMiddle()">
        <ng-content />
      </table>
    </div>
  `,
})
export class UiDataTableComponent {
  readonly alignMiddle = input<boolean>(true);
  readonly fixedRows = input<boolean>(true);
  readonly fixedHeight = input<boolean>(false);
  /** Visible body rows when {@link fixedHeight} is true (default 10). */
  readonly fixedRowCount = input<number>(10);
}
