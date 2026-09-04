---
name: coreui-styling
description: >-
  Applies the layered Angular design system: CoreUI for the application shell,
  Tailwind CSS for page content, and ds-* plus layout/shared components for
  established shared patterns. Use when creating or adjusting Angular UI.
---

# CoreUI Shell + Tailwind Content Design System

The UI uses a layered design system:

- **CoreUI/Bootstrap** provides the application shell, structure, navigation,
  responsive behavior, and framework-compatible components.
- **Tailwind CSS** provides page-level composition and visual detail: grids,
  cards, panels, spacing, typography, color, surfaces, gradients, emphasis,
  metrics, badges, and states.
- **`ds-*` classes and `layout/shared` components** provide established,
  reusable project patterns such as forms, tables, alerts, empty states, and
  loading states.

## Styling boundaries

Use the following boundaries consistently:

1. Use CoreUI and `@coreui/angular` for the shell: sidebar, header, footer,
   navigation, shell containers, color mode, and structural layout behavior.
2. Use Tailwind for new page content when Tailwind is configured in the target
   project. Prefer it for visual composition that needs richer hierarchy,
   colors, spacing, highlights, or responsive layouts.
3. Use `ds-*` and `layout/shared` when an existing shared component or
   established project pattern covers the requirement.
4. Do not use Tailwind to reimplement the CoreUI shell.
5. Do not use Bootstrap, Tailwind, and `ds-*` simultaneously for the same
   visual property on one element unless the combination is intentional and
   documented.

## Authoritative sources (priority order)

1. **CoreUI docs**: https://coreui.io/bootstrap/docs/getting-started/introduction/
2. **Project tokens and shared styles**:
   `src/styles/_tokens.scss`, `_ds-components.scss`, `_ds-forms.scss`
3. **Theme and shell**: `src/styles/_theme.scss`, `src/app/layout/`
4. **Existing reference screen**: Dashboard de Vendas
   (`src/app/pages/dashboard/dashboard-sales/`)
5. **Existing component and page patterns** in the target project

If `docs/design_ui.md` exists in the target project, use it as an additional
project-specific reference. Do not assume that file exists in every repository.

## Mandatory rules

- Use **`layout/shared` components** (`PageHeader`, `FilterBar`, `UiCard`, `StatCard`, `StatusBadge`, `EmptyState`, `UiSkeleton`) for new/migrated screens.
- Use **`ds-*` classes** for forms and tables when the shared classes exist —
  do not style repeated controls one-by-one.
- **CoreUI shell** stays: sidebar escura, `c-header`, `c-container`, `ColorModeService`.
- **Icons**: Font Awesome (`fas`, `fab`).
- **Custom CSS** only in `src/styles/custom/_<feature>.scss`, imported via
  `_custom.scss`, when CoreUI, Tailwind, or existing `ds-*` patterns cannot
  express the requirement cleanly.
- **No** loose global SCSS under `src/app/` (except truly local component styles that cannot be shared).

## Page template pattern

```html
<div class="space-y-6">
  <app-page-header title="..." subtitle="...">
    <button
      pageHeaderActions
      class="inline-flex items-center gap-2 rounded-lg bg-primary px-4 py-2 font-semibold text-white shadow-sm transition hover:bg-primary/90 focus:outline-none focus:ring-2 focus:ring-primary/40"
      type="button"
    >
      ...
    </button>
  </app-page-header>

  <app-filter-bar label="Filtros">
    <div class="grid grid-cols-1 gap-4 md:grid-cols-4">
      <div>
        <label class="mb-1 block text-sm font-semibold text-body" for="...">...</label>
        <input class="form-control ds-form-control" id="..." />
      </div>
    </div>
  </app-filter-bar>

  @if (errorMessage()) {
    <div class="ds-alert ds-alert--danger" role="alert">
      <i class="fas fa-circle-exclamation" aria-hidden="true"></i>
      <span>{{ errorMessage() }}</span>
    </div>
  }

  <app-ui-card title="..." icon="fas fa-..." [noPadding]="true">
    <app-ui-data-table>
      <!-- thead / tbody -->
    </app-ui-data-table>
  </app-ui-card>
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

## Prohibited / deprecated

- Legacy classes: `dashboard-kpi-*`, `dashboard-panel`, `dashboard-table-card`
- `ngx-skeleton-loader` / `ngx-loading` — use `UiSkeletonComponent`
- `ngx-pagination` — use manual pagination with `ds-panel__footer--pagination`
- Inventing a second design-token system outside the existing project tokens
- Replacing the CoreUI shell with custom Tailwind markup
- Mixing utility systems indiscriminately on the same element

## Workflow checklist

```
- [ ] Used layout/shared components where applicable
- [ ] Applied ds-form-control / ds-select on forms
- [ ] Tables use ds-table inside UiCard / UiDataTable
- [ ] Error state uses ds-alert
- [ ] Empty/loading use EmptyState / UiSkeleton
- [ ] CoreUI is used for the shell and Tailwind for new page-level composition
- [ ] Tailwind, Bootstrap, and ds-* are not redundantly styling the same property
- [ ] Visual hierarchy includes clear primary actions, highlights, and content grouping
- [ ] Hover, focus, loading, error, responsive, and dark-mode states were considered
- [ ] Custom CSS in src/styles/custom/ if needed
- [ ] Dark mode checked (body.c-dark-theme)
```
