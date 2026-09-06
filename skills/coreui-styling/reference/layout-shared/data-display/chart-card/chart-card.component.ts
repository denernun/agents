import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { UiSkeletonComponent } from '../../primitives/ui-skeleton';

/**
 * Overlay skeleton instead of swapping projected content.
 * Why: ApexCharts throws `Cannot read properties of undefined (reading 'startTime')`
 * when the chart DOM is detached while an animation timeout is still pending.
 */
@Component({
  selector: 'app-chart-card',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: { class: 'd-block h-100' },
  imports: [UiSkeletonComponent],
  template: `
    <div class="ds-panel">
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
        <ng-content select="[chartCardActions]" />
      </div>
      <div class="ds-panel__body ds-panel__body--chart position-relative">
        <div [class.invisible]="loading()">
          <ng-content />
        </div>
        @if (loading()) {
          <div class="position-absolute top-0 start-0 end-0">
            <app-ui-skeleton variant="chart" [height]="280" />
          </div>
        }
      </div>
    </div>
  `,
})
export class ChartCardComponent {
  readonly title = input.required<string>();
  readonly subtitle = input<string | undefined>(undefined);
  readonly icon = input<string | undefined>(undefined);
  readonly loading = input<boolean>(false);
}
