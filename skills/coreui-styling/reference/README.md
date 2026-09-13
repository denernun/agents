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

## `styles/_ds-modals.scss` — conditional 5th file

Themes sweetalert2's own classes (`.swal2-*`) with the `--ds-*` tokens. Only
copy this into a project that depends on `sweetalert2` (check its
`package.json`). Wire it from `_custom.scss` with `@use 'ds-modals';` (the
file lives at `src/styles/_ds-modals.scss`, sibling of `_tokens.scss` — not
under `custom/`, since it is canonical, not a per-project exception). Never
touches `ds-*` classes, so it carries zero collision risk with the four core
files.

Kanban board styling (`ds-kanban-*`) is **not** part of the canonical set —
it is a per-app pattern for pipeline/CRM-style boards, today only
`crmclass-app`. Each app that needs one keeps its own
`custom/_<app>-kanban.scss` built on the same `--ds-*` tokens, documented as
an exception in that project's `docs/design_ui.md`.

## `styles/_ds-datepicker.scss` — conditional 5th file (ngx-bootstrap)

Themes `ngx-bootstrap`'s own datepicker/daterangepicker classes
(`.bs-datepicker-*`) with the `--ds-*` tokens — only takes effect when the
app sets `containerClass: 'ds-datepicker'` on its `BsDatepickerConfig` /
`BsDaterangepickerConfig` (design-system.md §50.5), replacing the stock
hardcoded theme names (`theme-blue`, `theme-dark-blue`, …) that ship with
`ngx-bootstrap` and ignore dark mode entirely. Copy into a project that
depends on `ngx-bootstrap` (nearly the whole fleet). Wire with
`@use 'ds-datepicker';` in `styles.scss`, after `ds-forms`.

## `layout-shared/` — the Angular components (copy + adapt one file)

Mirror of `src/app/layout/shared/` — the presentational components that consume
the `ds-*` classes (`app-page-header`, `app-stat-card`, `app-ui-card`,
`app-chart-card`, `app-status-badge`, `app-ui-data-table`, `app-empty-state`,
`app-ui-skeleton`, `app-ui-button`, `app-ui-modal`, `app-ui-dropdown`,
`app-insight-alert`, `app-period-segment`, `app-date-range-filter`,
`app-ui-table-cell-text`, `app-ui-table-pagination`, `app-filter-bar`). APIs
documented in `../design-system.md` §11.

`app-date-range-filter` depends on `ngx-bootstrap` (`BsDatepickerModule`,
`BsDropdownModule`) and `dayjs` — both already standard across the fleet.
It is the reference pattern for "quick-select + `bsDaterangepicker`"; a
project with a more advanced service-backed date filter (persisted across
routes, extra presets) does not need to replace that with this component —
see design-system.md §11.15 for when each shape applies. **Never build a
custom calendar/date-range widget instead of `bsDaterangepicker` —
`ngx-bootstrap` already has one.**

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
