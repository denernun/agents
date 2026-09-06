import { ChangeDetectionStrategy, Component, input } from '@angular/core';

export type UiSkeletonVariant = 'text' | 'card' | 'circle' | 'chart';

/**
 * Loading placeholder with pulse animation.
 */
@Component({
  selector: 'app-ui-skeleton',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    @switch (variant()) {
      @case ('card') {
        <div class="ds-skeleton ds-skeleton--card">
          <div class="ds-skeleton mb-3" style="height: 14px; width: 35%"></div>
          <div class="ds-skeleton mb-2" style="height: 28px; width: 55%"></div>
          <div class="ds-skeleton" style="height: 12px; width: 40%"></div>
        </div>
      }
      @case ('circle') {
        <div class="ds-skeleton rounded-circle" [style.width.px]="size()" [style.height.px]="size()"></div>
      }
      @case ('chart') {
        <div class="ds-skeleton ds-skeleton--chart" [style.min-height.px]="height()"></div>
      }
      @default {
        <div class="ds-skeleton" [style.height.px]="height()"></div>
      }
    }
  `,
})
export class UiSkeletonComponent {
  readonly variant = input<UiSkeletonVariant>('text');
  readonly height = input<number>(16);
  readonly size = input<number>(40);
}
