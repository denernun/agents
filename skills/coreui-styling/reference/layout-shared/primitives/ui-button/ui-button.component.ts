import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';

export type UiButtonVariant =
  'primary' | 'secondary' | 'success' | 'danger' | 'warning' | 'info' | 'outline-primary' | 'outline-secondary' | 'outline-success' | 'outline-danger' | 'link';

export type UiButtonSize = 'sm' | 'md' | 'lg';

/**
 * Design-system button wrapping Bootstrap btn classes with consistent sizing.
 */
@Component({
  selector: 'app-ui-button',
  changeDetection: ChangeDetectionStrategy.OnPush,
  template: `
    <button [attr.type]="type()" class="btn ds-focus-ring" [class]="buttonClass()" [disabled]="disabled() || loading()" (click)="clicked.emit()">
      @if (loading()) {
        <span class="spinner-border spinner-border-sm me-2" role="status" aria-hidden="true"></span>
      } @else if (icon()) {
        <i class="me-2" [class]="icon()" aria-hidden="true"></i>
      }
      <ng-content />
    </button>
  `,
})
export class UiButtonComponent {
  readonly variant = input<UiButtonVariant>('primary');
  readonly size = input<UiButtonSize>('md');
  readonly type = input<'button' | 'submit' | 'reset'>('button');
  readonly icon = input<string | undefined>(undefined);
  readonly disabled = input<boolean>(false);
  readonly loading = input<boolean>(false);
  readonly block = input<boolean>(false);
  readonly clicked = output<void>();

  readonly buttonClass = computed((): string => {
    const sizeClass: string = this.size() === 'md' ? '' : `btn-${this.size()}`;
    const blockClass: string = this.block() ? 'w-100' : '';
    return [`btn-${this.variant()}`, sizeClass, blockClass].filter(Boolean).join(' ');
  });
}
