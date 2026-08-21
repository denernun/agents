---
name: coreui-styling
description: >-
  Applies CoreUI + erpclass-dash design system (ds-* classes, layout/shared components)
  for layouts, pages, forms, and tables. Use when creating or adjusting UI in this project.
---

# CoreUI + Design System (erpclass-dash)

The UI stacks **CoreUI/Bootstrap** (structure, grid, behavior) with a project design system (`ds-*` SCSS + `layout/shared` Angular components).

## Authoritative sources (priority order)

1. **CoreUI docs**: https://coreui.io/bootstrap/docs/getting-started/introduction/
2. **Project design system**: `docs/design_ui.md` (única referência de layout / DS)

3. **Global SCSS**: `src/styles/_tokens.scss`, `_ds-components.scss`, `_ds-forms.scss`
4. **Theme/layout**: `src/styles/_theme.scss`, `src/app/layout/`
5. **Reference screen**: Dashboard de Vendas (`src/app/pages/dashboard/dashboard-sales/`)

## Mandatory rules

- Use **`layout/shared` components** (`PageHeader`, `FilterBar`, `UiCard`, `StatCard`, `StatusBadge`, `EmptyState`, `UiSkeleton`) for new/migrated screens.
- Use **`ds-*` classes** for forms and tables — do not style inputs one-by-one.
- **CoreUI shell** stays: sidebar escura, `c-header`, `c-container`, `ColorModeService`.
- **Icons**: Font Awesome (`fas`, `fab`).
- **Custom CSS** only in `src/styles/custom/_<feature>.scss`, imported via `_custom.scss`.
- **No** loose global SCSS under `src/app/` (except truly local component styles that cannot be shared).

## Page template pattern

```html
<div class="container-fluid px-0">
  <app-page-header title="..." subtitle="...">
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
- Inventing parallel color/spacing systems outside `--ds-*` tokens

## Workflow checklist

```
- [ ] Used layout/shared components where applicable
- [ ] Applied ds-form-control / ds-select on forms
- [ ] Tables use ds-table inside UiCard / UiDataTable
- [ ] Error state uses ds-alert
- [ ] Empty/loading use EmptyState / UiSkeleton
- [ ] Custom CSS in src/styles/custom/ if needed
- [ ] Dark mode checked (body.c-dark-theme)
```
