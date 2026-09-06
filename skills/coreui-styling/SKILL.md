---
name: coreui-styling
description: >-
  Applies the ONE layered Angular design system shared by every CLASS front-end
  (CoreUI shell + ds-* + layout/shared), defined by this skill's canonical spec
  and reference SCSS. Use when creating or adjusting Angular UI. Enforces a
  single card style across projects and a strict dark-mode / typography
  contrast contract (never dark text on a dark surface).
---

# CoreUI Shell + Design System

Every Angular front-end in the CLASS families (ERPCLASS, NFECLASS, SHOPCLASS,
MOBICLASS, CRMCLASS) — `erpclass-dash`, `erpclass-admin`, `erpclass-cob`,
`erpclass-cota`, `erpclass-suporte`, `erpclass-connect`, `erpclass-mkt`,
`erpclass-www`, `crmclass-app`, … — uses **one** layered design system. It must
look the same across all of them — same shell, same cards, same grids, same
tokens, same dark mode. Divergent per-project styling is a defect to fix, not a
choice.

**This skill is the canonical design system** — the style was distilled once
from `erpclass-dash` and now lives here, tied to no project. Bundled:

- [`design-system.md`](design-system.md) — the written spec (51 sections):
  element rules, tokens, sizes, component APIs, `ds-*` inventory.
- [`reference/styles/`](reference/) — the canonical SCSS: `_tokens.scss`,
  `_ds-components.scss`, `_ds-forms.scss`, `_theme.scss`. A project's four
  files must be **byte-identical** to these.
- [`reference/layout-shared/`](reference/) — the canonical Angular components
  (`app-page-header`, `app-stat-card`, `app-ui-card`, `app-chart-card`,
  `app-status-badge`, `app-ui-data-table`, `app-empty-state`, `app-ui-skeleton`,
  `app-ui-button`, `app-ui-modal`, `app-ui-dropdown`, `app-insight-alert`,
  `app-period-segment`, `app-filter-bar`, `app-ui-table-cell-text`,
  `app-ui-table-pagination`). Copy into `src/app/layout/shared/`; only
  `tokens/ui-tokens.ts` grows per-project (domain status→accent mappers).

A project's `docs/design_ui.md`, if it exists at all, is only a pointer to this
skill plus documented per-project exceptions — never a copy of the spec, never
a reference to another project's design.

- **CoreUI/Bootstrap** provides the application shell, structure, navigation,
  responsive behavior, and framework-compatible components.
- **`ds-*` classes and `layout/shared` components** provide established,
  reusable patterns: cards, forms, tables, KPI cards, charts, alerts, badges,
  empty states, and loading states.
- **Tokens in `src/styles/_tokens.scss`** are the single source of every color,
  surface, border, radius, shadow, and font. Nothing visual is hardcoded.

## Cross-project consistency (mandatory)

1. **Reference:** this skill — `design-system.md` (spec) and `reference/styles/`
   (canonical SCSS). Not another project's repo.
2. **Before inventing any style**, check the spec and the reference SCSS for an
   existing token / `ds-*` class / `layout/shared` component that covers it.
3. A project's `src/styles/_tokens.scss`, `_ds-components.scss`, `_ds-forms.scss`
   and `_theme.scss` must be **byte-identical** to `reference/styles/`. Same
   variable names, same light/dark blocks, same values. Never fork the palette.
4. To change the design system: edit the skill (spec + `reference/styles/`),
   then sync the four SCSS files into every project. A per-project divergence
   is a defect unless it is a documented exception in that project's
   `docs/design_ui.md`, layered in `src/styles/custom/_<feature>.scss`.

## One card style (mandatory)

There is exactly one card in the system. Every boxed surface — KPI, chart panel,
table container, form section, info box — is one of:

| Use case | Component / class |
|----------|-------------------|
| KPI / metric tile | `app-stat-card` + `ds-kpi-grid ds-kpi-grid--N` |
| Chart / content panel | `app-chart-card` → `ds-panel` (`ds-panel__header` / `__body` / `__footer`) |
| Generic container (table, form block) | `app-ui-card` / `ds-panel` |

Every card, in light and dark, gets its look **only** from tokens:

- background `--ds-surface` (never `#fff`, never `white`, never a raw hex)
- border `1px solid var(--ds-border)`
- radius `var(--ds-radius-card)`
- shadow `var(--ds-shadow-card)` (hover `--ds-shadow-card-hover`)
- text `var(--ds-text)` / muted `var(--ds-text-muted)`

Prohibited: bespoke `.card` restyles, one-off `box-shadow` / `border-radius` /
`border` on a panel, per-screen KPI markup, top accent stripes on KPI cards
(use `variant="hero"` instead), colored card backgrounds outside the
`--ds-*-50/100` tint tokens.

## Dark mode & typography contract (non-negotiable)

Dark mode is the #1 source of regressions across projects. The recurring bugs:
**dark text on a dark surface**, **light text on a light surface**, and fonts
that look "out of context" because a component hardcoded its own color or size.
Root cause is always the same: a value was hardcoded instead of read from a
token that flips per theme.

### Theme source of truth

- The real theme lives on `document.documentElement` as
  `data-coreui-theme="light" | "dark"` (CoreUI `ColorModeService`).
- `_tokens.scss` redefines every `--ds-*` variable under
  `html[data-coreui-theme='dark'], body.c-dark-theme`.
- `AppComponent` mirrors `body.c-dark-theme` from `data-coreui-theme` for legacy
  selectors. Read `document.documentElement.dataset.coreuiTheme` in TS — never
  `body` alone.

### Rules

1. **Never hardcode a text color.** No `color: #111`, `#1e293b`, `#333`, `black`,
   `white`, `rgb(...)`, no Bootstrap `.text-dark` / `.text-black` / `.text-white`
   / `.text-body` on content. Text is `var(--ds-text)` or `var(--ds-text-muted)`
   (or inherits from a parent that sets one).
2. **Never hardcode a surface/background.** Backgrounds come from `--ds-surface`,
   `--ds-surface-muted`, `--ds-surface-header`, or a `--ds-*-50/100` tint token.
3. **Background and text always move together.** If you set a background, set (or
   inherit) a token-based text color that has guaranteed contrast against it in
   both themes. Same the other way around.
4. **Soft/tinted cards** (`--ds-*-50` / `--ds-*-100`): body text stays
   `--ds-text`; the icon/accent uses the strong color token (`--ds-success`,
   `--ds-danger`, …) which is legible on the tint in both themes.
5. **Never override a component's font.** No per-component `font-family` or
   ad-hoc `font-size` in px. Font is `var(--ds-font-sans)` globally; size and
   weight come from the shared type scale / `ds-*` classes. If text "looks out of
   context", it is almost always a local override — delete it.
6. **Badges/status:** use `ds-badge--*`. Do not re-tint badges per theme
   (regresses contrast); the badge tokens already handle both.
7. **ApexCharts:** follow the `dashboard-chart.theme.ts` +
   `app-dashboard-apex-chart` pattern (`design-system.md` §22 / §50.3).
   `theme.mode` follows `isDarkThemeActive()`. Read CSS
   tokens from **`document.body` first in dark mode** (index.html bootstraps
   `body.c-dark-theme` before `html` gets `data-coreui-theme`). Axis labels use
   `--ds-text`; legend/title use `--ds-text-muted`. The chart wrapper re-applies
   colors on `erpclass-*-colorScheme`. Classic bug: `theme.mode='dark'` while
   labels still resolve light tokens from `:root` on `html` → dark text on dark
   chart background (ex.: “Maiores Devedores”).

### Verify every time

Toggle light ↔ dark with the header switcher and visually check: page
background, every card surface + its title/value/subtitle, muted helper text,
table header + rows, badges, form controls + placeholders, chart axes / legend /
tooltip, empty state, alert. Nothing invisible, nothing low-contrast.

## Styling boundaries

1. Use CoreUI and `@coreui/angular` for the shell: sidebar, header, footer,
   navigation, shell containers, color mode, structural layout behavior.
2. Use `ds-*` and `layout/shared` for all repeated visual patterns — do not
   style KPIs, tables, cards, or chart panels one-off per screen.
3. Do not use Tailwind or parallel utility systems for page composition — use
   Bootstrap grid + `ds-*` per `design-system.md`.
4. Do not reimplement the CoreUI shell with custom markup.

## Authoritative sources (priority order)

1. **`design-system.md`** bundled in this skill — the written spec (element
   rules, tokens, sizes, component APIs, `ds-*` inventory)
2. **`reference/styles/`** bundled in this skill — canonical
   `_tokens.scss` / `_ds-components.scss` / `_ds-forms.scss` / `_theme.scss`;
   a project's four files must match these byte-for-byte
3. **`docs/design_ui.md`** in the target project — only a pointer to (1) plus
   documented per-project exceptions; never a forked copy, never a link to
   another project
4. **CoreUI docs**: https://coreui.io/bootstrap/docs/getting-started/introduction/

## Mandatory rules

- Use **`layout/shared` components** (`PageHeader`, `FilterBar`, `UiCard`, `StatCard`, `ChartCard`, `StatusBadge`, `EmptyState`, `UiSkeleton`) for new/migrated screens.
- Use **`ds-*` classes** for forms and tables when the shared classes exist.
- All colors, surfaces, borders, radii, shadows, and fonts come from `--ds-*` tokens.
- **CoreUI shell** stays: sidebar, `c-header`, `c-container`, `ColorModeService`.
- **Icons**: Font Awesome (`fas`, `fab`).
- **Custom CSS** only in `src/styles/custom/_<feature>.scss`, imported via
  `_custom.scss`, when CoreUI or existing `ds-*` patterns cannot express the requirement cleanly.
- **No** loose global SCSS under `src/app/` (except truly local component styles that cannot be shared).

## Page template pattern

```html
<div class="w-100 d-flex flex-column gap-4">
  <app-page-header title="..." subtitle="..." icon="fas fa-...">
    <button pageHeaderActions class="btn btn-primary" type="button">...</button>
  </app-page-header>

  <app-filter-bar label="Filtros">
    <div class="col-md-4">
      <label class="form-label fw-semibold" for="...">...</label>
      <input class="form-control ds-form-control" id="..." />
    </div>
  </app-filter-bar>

  @if (errorMessage()) {
    <div class="ds-alert ds-alert--danger mb-4" role="alert">
      <i class="fas fa-circle-exclamation" aria-hidden="true"></i>
      <span>{{ errorMessage() }}</span>
    </div>
  }

  <div class="ds-kpi-grid ds-kpi-grid--4">
    <app-stat-card variant="hero" title="..." value="..." icon="fas fa-..." color="success" />
  </div>

  <div class="ds-dashboard-grid ds-dashboard-grid--two">
    <app-chart-card title="..." icon="fas fa-chart-line">
      <app-dashboard-apex-chart [options]="chartOptions" />
    </app-chart-card>
  </div>
</div>
```

## ng-select combo

```html
<ng-select
  class="ds-select"
  panelClass="ds-select-panel"
  appendTo="body"
  ...
></ng-select>
```

## Custom SCSS organization

| Location | Purpose |
|----------|---------|
| `src/styles/_custom.scss` | Barrel — `@use 'custom/<name>'` |
| `src/styles/custom/_<feature>.scss` | Feature styles (e.g. `_auth-social.scss`) |
| `src/styles/_ds-components.scss` | Shared ds-* component classes |
| `src/styles/_ds-forms.scss` | Form control classes |
| `src/styles/_tokens.scss` | Light/dark CSS variables (byte-identical to `reference/styles/`) |

## Prohibited / deprecated

- Legacy classes: `dashboard-kpi-*`, `dashboard-panel`, `dashboard-table-card`
- `ngx-skeleton-loader` / `ngx-loading` — use `UiSkeletonComponent`
- `ngx-pagination` — use manual pagination with `ds-panel__footer--pagination`
- Inventing a second design-token system outside `_tokens.scss`
- Hardcoded colors / surfaces / fonts anywhere (`#fff`, `#111`, `black`, `white`,
  `.text-dark`, `.text-white`, `font-family`, px `font-size` overrides)
- Bespoke card styling — one-off `box-shadow` / `border` / `border-radius` on a panel
- KPI cards with a top accent stripe (use `variant="hero"`)
- Per-theme badge re-tinting
- Chart theme resolving light tokens from `html` while `body.c-dark-theme` is active
- Chart axis colors set only at data-load without wrapper re-apply on colorScheme
- Tailwind for page layout (use Bootstrap grid + `ds-*`)

## ApexCharts (mandatory pattern)

`dashboard-chart.theme.ts` + `app-dashboard-apex-chart` wrapper:

| Concern | Rule |
| -------- | ---- |
| Theme detection | `html[data-coreui-theme]` then fallback `body.c-dark-theme` |
| Token source | `document.body` first when dark (bootstrap class in `index.html`) |
| Axis / scale labels | `--ds-text` via `getDashboardChartAxisColor()` |
| Legend / title | `--ds-text-muted` via `getDashboardChartForeColor()` |
| Grid | `--ds-border` via `getDashboardChartGridColor()` |
| Theme toggle | `app-dashboard-apex-chart` listens `erpclass-*-colorScheme` and re-applies |
| Builders | Always `buildDashboard*ChartOptions()` — no inline Apex config in widgets |
| QA | Toggle light/dark on every chart screen; horizontal bar category names must stay readable |

```typescript
// dashboard-chart.theme.ts — token read order
const sources = isDarkThemeActive()
  ? [document.body, document.documentElement]
  : [document.documentElement, document.body];
```

Do **not** set `theme.mode: 'dark'` with light-mode `--ds-text` tokens — that produces the unreadable axis labels seen on “Maiores Devedores”.

## Data grids (mandatory pattern)

See `design-system.md` §11.5 / §38.

| Concern | Rule |
| -------- | ---- |
| Page size | **10 rows** default — use `DS_TABLE_PAGE_SIZE` from `@app/layout/shared` |
| Pagination | Footer `ds-panel__footer--pagination` always visible when grid has data; Anterior/Próximo + `página X de Y` |
| Wrapper | `app-ui-data-table` or `table.ds-table.ds-table--fixed-rows` |
| Text cells | `app-ui-table-cell-text` — single line, ellipsis, full value in native `title` tooltip |
| Row height | `ds-table--fixed-rows` keeps uniform row height (no multi-line text in cells) |
| Server-side | Pass `pageSize: DS_TABLE_PAGE_SIZE` to API; reset to page 1 on filter change |

```html
<app-ui-data-table>
  <thead>...</thead>
  <tbody>
    <tr>
      <td>
        <app-ui-table-cell-text [value]="row.nome" [tooltip]="fullLabel" [emphasis]="true" />
      </td>
    </tr>
  </tbody>
</app-ui-data-table>

<div uiCardFooter class="ds-panel__footer--pagination">
  <small class="text-body-secondary">{{ total }} registro(s) — página {{ page }} de {{ totalPages }}</small>
  <nav aria-label="Paginação">...</nav>
</div>
```

Prohibited in grids: `<br />` inside text cells, wrapping long descriptions, variable row height from stacked content.

## Workflow checklist

```
- [ ] Matches `design-system.md` (tokens, sizes, component APIs)
- [ ] Used layout/shared components where applicable
- [ ] Every card is stat-card / chart-card / ui-card — no bespoke card CSS
- [ ] Dashboard KPIs use stat-card variant="hero" + ds-kpi-grid--N
- [ ] Chart panels use app-chart-card + dashboard-chart.theme.ts
- [ ] Data grids: 10 rows/page, ds-table--fixed-rows, ui-table-cell-text, pagination footer
- [ ] No hardcoded color / surface / font — all from --ds-* tokens
- [ ] Applied ds-form-control / ds-select on forms
- [ ] Tables use ds-table inside UiCard / UiDataTable
- [ ] Error state uses ds-alert
- [ ] Empty/loading use EmptyState / UiSkeleton
- [ ] Toggled light ↔ dark and checked every surface: no dark-on-dark,
      no light-on-light, no out-of-context fonts (cards, text, tables,
      badges, forms, chart axis/legend/tooltip)
```
