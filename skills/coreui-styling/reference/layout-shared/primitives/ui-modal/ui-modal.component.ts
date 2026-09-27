import { ChangeDetectionStrategy, Component, computed, input, output } from '@angular/core';

export type UiModalSize = 'md' | 'lg' | 'xl';

const MODAL_SIZE_CLASS: Record<UiModalSize, string> = {
  md: '',
  lg: 'ds-modal--lg',
  xl: 'ds-modal--xl',
};

/**
 * Presentational modal shell with backdrop, Escape-to-close, and footer slot.
 */
@Component({
  selector: 'app-ui-modal',
  changeDetection: ChangeDetectionStrategy.OnPush,
  host: {
    class: 'ds-modal-host',
    '(document:keydown.escape)': 'onEscape()',
  },
  template: `
    <div class="ds-modal-backdrop" (click)="onBackdropClick()" aria-hidden="true"></div>
    <div class="ds-modal" [class]="sizeClass()" role="dialog" aria-modal="true" [attr.aria-labelledby]="titleId">
      <div class="ds-modal__header">
        <h2 class="ds-modal__title" [id]="titleId">{{ title() }}</h2>
        <button type="button" class="btn-close ds-focus-ring" aria-label="Fechar" (click)="closed.emit()"></button>
      </div>
      <div class="ds-modal__body">
        <ng-content />
      </div>
      <ng-content select="[uiModalFooter]" />
    </div>
  `,
})
export class UiModalComponent {
  readonly title = input.required<string>();
  readonly closeOnBackdrop = input<boolean>(true);
  /** Widens the dialog past the default 32rem — `lg` for content like data tables, `xl` for wider grids. */
  readonly size = input<UiModalSize>('md');
  readonly closed = output<void>();

  readonly titleId: string = `ds-modal-title-${Math.random().toString(36).slice(2, 9)}`;
  readonly sizeClass = computed((): string => MODAL_SIZE_CLASS[this.size()]);

  public onEscape(): void {
    this.closed.emit();
  }

  public onBackdropClick(): void {
    if (!this.closeOnBackdrop()) return;
    this.closed.emit();
  }
}
