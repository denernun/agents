import { ChangeDetectionStrategy, Component, input } from '@angular/core';
import { BsDropdownModule } from 'ngx-bootstrap/dropdown';

export type UiDropdownVariant = 'outline-secondary' | 'outline-primary' | 'primary' | 'secondary';

/**
 * Dropdown menu shell using ngx-bootstrap behavior and ds-* surface styling.
 */
@Component({
  selector: 'app-ui-dropdown',
  changeDetection: ChangeDetectionStrategy.OnPush,
  imports: [BsDropdownModule],
  template: `
    <div class="btn-group ds-dropdown" dropdown [placement]="placement()">
      <button dropdownToggle type="button" class="btn dropdown-toggle ds-focus-ring" [class]="'btn-' + variant()" [attr.aria-label]="ariaLabel() || label()">
        @if (icon()) {
          <i class="me-2" [class]="icon()" aria-hidden="true"></i>
        }
        {{ label() }}
      </button>
      <ul *dropdownMenu class="dropdown-menu ds-dropdown__menu" role="menu">
        <ng-content />
      </ul>
    </div>
  `,
})
export class UiDropdownComponent {
  readonly label = input.required<string>();
  readonly icon = input<string | undefined>(undefined);
  readonly variant = input<UiDropdownVariant>('outline-secondary');
  readonly placement = input<string>('bottom left');
  readonly ariaLabel = input<string | undefined>(undefined);
}
