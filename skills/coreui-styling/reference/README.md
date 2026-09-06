# Canonical design-system source

These files are the **single source of truth** for the shared Angular design
system used by every CLASS front-end. They are not tied to any project — the
style was distilled once from `erpclass-dash` and now lives here.

## `styles/` — the four SCSS files (byte-identical per project)

| File | Role |
|------|------|
| `styles/_tokens.scss` | Every `--ds-*` variable, light + dark blocks. Colors, surfaces, borders, radii, shadows, fonts, tints, gradients, ranking. |
| `styles/_ds-components.scss` | `ds-*` component classes: panels, stat cards, KPI/dashboard grids, tables, badges, ranking, empty, skeleton, alerts, modal, dropdown, insight-alert, segment, focus, micro-interactions. |
| `styles/_ds-forms.scss` | Form controls: `ds-form-control`, `ds-select` (+ panel), search field, input group, `ds-kbd`, pagination footer. |
| `styles/_theme.scss` | CoreUI shell overrides (body, header height, sidebar, footer). |

A project's `src/styles/` copies of these must be **byte-identical**. `styles.scss`
wires them: `@use 'tokens';` first, then after `@use 'theme';` add
`@use 'ds-components';` and `@use 'ds-forms';`.

## `layout-shared/` — the Angular components (copy + adapt one file)

Mirror of `src/app/layout/shared/` — the presentational components that consume
the `ds-*` classes (`app-page-header`, `app-stat-card`, `app-ui-card`,
`app-chart-card`, `app-status-badge`, `app-ui-data-table`, `app-empty-state`,
`app-ui-skeleton`, `app-ui-button`, `app-ui-modal`, `app-ui-dropdown`,
`app-insight-alert`, `app-period-segment`, `app-ui-table-cell-text`,
`app-ui-table-pagination`, `app-filter-bar`). APIs documented in
`../design-system.md` §11.

Copy the folder into `src/app/layout/shared/`. **One file is project-specific:**
`tokens/ui-tokens.ts` here has only the generic pieces (`UiAccentColor`,
`UI_ACCENT_ICON_CLASSES`, `mapActiveAccent`) — each project adds its own
domain status→accent mappers next to its models, returning `UiAccentColor`.
`app-stat-card` etc. use one `NumberPipe`/`DecimalPipe` — keep whichever the
project already has.

## How a project uses these

1. `src/styles/*` byte-identical to `styles/*`; `layout/shared/*` a copy of
   `layout-shared/*` (only `tokens/ui-tokens.ts` grows project mappers).
2. To change the design system: edit **here**, in the hub, then sync into each
   project and commit. Never fork per project.
3. A genuine per-project need is a documented exception in that project's
   `docs/design_ui.md`, layered in `src/styles/custom/_<feature>.scss` — never
   an edit to the canonical SCSS.

The written spec (element rules, sizes, component APIs) is `../design-system.md`.
