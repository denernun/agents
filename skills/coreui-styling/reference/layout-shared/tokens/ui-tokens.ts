/** Semantic accent colors for stat cards and badges. */
export type UiAccentColor = 'primary' | 'success' | 'info' | 'warning' | 'danger' | 'neutral';

/** Maps accent tokens to CoreUI utility class groups. */
export const UI_ACCENT_ICON_CLASSES: Record<UiAccentColor, string> = {
  primary: 'bg-primary-subtle text-primary',
  success: 'bg-success-subtle text-success',
  info: 'bg-info-subtle text-info',
  warning: 'bg-warning-subtle text-warning',
  danger: 'bg-danger-subtle text-danger',
  neutral: 'bg-body-secondary text-body-secondary',
};

/** Maps active/inactive flag to badge accent. */
export function mapActiveAccent(isActive: boolean): UiAccentColor {
  return isActive ? 'success' : 'neutral';
}

// ─────────────────────────────────────────────────────────────────────────────
// Domain-specific status → accent/label mappers belong in the PROJECT, not here.
// Each app adds its own next to its models (e.g. `data/models/<x>/<x>.tokens.ts`)
// returning `UiAccentColor`. Keep this file limited to the generic pieces above.
// ─────────────────────────────────────────────────────────────────────────────
