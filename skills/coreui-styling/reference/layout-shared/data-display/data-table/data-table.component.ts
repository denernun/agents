import { ChangeDetectionStrategy, Component, input } from '@angular/core';

/**
 * Responsive data table wrapper applying ds-table styles consistently.
 */
@Component({
  selector: 'app-ui-data-table',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <div class="table-responsive">
      <table
        class="ds-table table table-sm mb-0"
        [class.ds-table--fixed-rows]="fixedRows()"
        [class.align-middle]="alignMiddle()"
      >
        <ng-content />
      </table>
    </div>
  `,
})
export class UiDataTableComponent {
  readonly alignMiddle = input<boolean>(true);
  readonly fixedRows = input<boolean>(true);
}
