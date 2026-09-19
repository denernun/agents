---
name: angular-coreui
description: Angular 22+ Clean Architecture + CoreUI conventions for admin/dash/app frontends. Use when editing Angular TypeScript UI in *-admin, *-dash, *-app.
---
You are a senior TypeScript engineer specializing in Angular (v22+) and Clean Architecture, with strong focus on SOLID principles, Clean Code, and reactive programming patterns.

Generate code, corrections, and refactorings that strictly adhere to the following principles, architecture, and nomenclature rules for Angular apps in this family (admin/dash/app).

> **These rules are mandatory and non-negotiable for every Angular app in this
> family.** They are not preferences. New code must comply, and any code you
> touch must be brought into compliance. "Prefer" below means "do this unless a
> documented, reviewed exception exists" — not "optional".

## TypeScript & Clean Code Guidelines

### Basic Principles
- Use English for all code symbols, documentation, comments, and commit messages.
- Explicitly declare the type of every variable, property, function parameter, and function return value.
  - Strictly avoid `any` or `unknown` without guard checks.
  - Create composite types, interfaces, or domain models when primitive types are insufficient.
- Use JSDoc to document public classes, interfaces, repositories, and public methods.
- Do not leave empty blank lines inside function bodies.
- Enforce one primary export per file.

### Nomenclature & Conventions
- Use **PascalCase** for classes, interfaces, types, components, directives, pipes, services, and enums.
- Use **camelCase** for variables, properties, methods, signals, functions, and parameters.
- Use **kebab-case** for file names and directory names (e.g., `account.repository.ts`, `auth.service.ts`).
- Use **UPPERCASE** with underscores for environment variables, constant values, and enum values.
- Function/Method names must start with a verb (e.g., `executeX`, `saveX`, `fetchAccount`, `calculateTotal`).
  - Boolean returning functions must start with `is`, `has`, `can`, or `should` (e.g., `isUserVerified`, `hasPermission`).
- Boolean variables/signals must be prefixed with boolean verbs (e.g., `isLoading`, `hasError`, `canDelete`, `sidebarShow`).
- Use clear, unabbreviated names (e.g., `accountRepository` instead of `accRepo`). Standard exceptions allowed: `i`, `j` in loops, `err` for errors, `req`/`res` for network payloads.

### Functions & Methods
- Write small, single-purpose functions (fewer than 20 instructions).
- Avoid block nesting by using early returns and guard clauses.
- Use array higher-order functions (`map`, `filter`, `reduce`) over traditional loops.
  - Use concise arrow functions for simple expressions.
- Prefer default parameter values instead of checking for `null` or `undefined`.
- Apply RO-RO (Receive Object, Return Object) pattern when passing multiple parameters (3+) to functions or returning multiple outputs.
- Keep a single level of abstraction per function.

### Data & State Handling
- Encapsulate data in composite domain types or models (`src/app/data/models/`).
- Signals are the single source of truth for local and application state. Keep writable `signal()` state minimal and derive everything else with `computed()`.
- Prefer immutability: use `readonly` for non-reassigned properties and `as const` for fixed object/array literals. Update signal state immutably (`update`/`set` with new references), never by mutating the held object.
- Validate inputs inside domain model/class constructors or factory methods rather than scattering inline checks across services.

### Classes & OOP
- Strictly follow SOLID principles: Single Responsibility, Open-Closed, Liskov Substitution, Interface Segregation, and Dependency Inversion.
- Prefer composition over inheritance.
- Define interfaces for abstraction contracts.
- Keep classes concise (fewer than 200 instructions, fewer than 10 public methods, fewer than 10 properties).

### Memory Safety & Exceptions
- Handle unexpected errors with custom domain exceptions or pass them to the global error handler (`ErrorHandlerUser`).
- Always clean up RxJS subscriptions using `takeUntilDestroyed(destroyRef)` or convert Observables to Signals via `toSignal()`.

---

## Specific to Angular 22+ & Clean Architecture

### Architecture & Layer Responsibilities
The project is structured under `src/app/` adhering to Clean Architecture principles:
- **Presentation Layer (`src/app/pages/`, `src/app/shared/`)**:
  - UI pages and shared components. All components must be **standalone**.
  - Keep presentation components clean: delegate business logic and data manipulation to services/repositories.
- **Domain & Data Layer (`src/app/data/`)**:
  - Models (`data/models`): Define core data structures and entities.
  - Repositories (`data/repository`): Data access abstraction extending `BaseRepository<T>` and instantiating via `FactoryRepository`.
  - Data Services (`data/services`): Services performing raw data manipulation.
- **Gateway Layer (`src/app/gateway/`)**:
  - API Service (`gateway/api`) and functional HTTP Interceptors (`api.interceptor.ts`).
  - Encapsulates direct HTTP calls, token authorization headers, and backend communication protocols.
- **Service & Application Layer (`src/app/services/`, `src/app/auth/`)**:
  - Application services managing business logic, state, user sessions, event buses (`EventsService`), and device capabilities (`DeviceService`).
- **Core Error Layer (`src/app/error/`)**:
  - Centralized global exception handler (`ErrorHandlerUser`).

### Angular Modern Features
- **Standalone Architecture**: All components, directives, and pipes are standalone. Do not use legacy `@NgModule` declarations.
  - **Never write `standalone: true`** in a decorator — it is the default since Angular v20 and adding it is flagged as outdated. Only ever write `standalone: false` for a deliberate, documented legacy exception.
- **Native Control Flow (mandatory)**: Use built-in `@if`, `@for`, `@switch` in templates. Never use the legacy structural directives `*ngIf`, `*ngFor`, `*ngSwitch`. Every `@for` must declare a `track` expression.
  - Use `@defer` (with `@placeholder` / `@loading` / `@error`) to lazily load heavy, below-the-fold, or interaction-triggered UI.
- **Change Detection**: Every component must set `changeDetection: ChangeDetectionStrategy.OnPush`. Templates read Signals directly (e.g. `{{ user() }}`); do not call methods that recompute in the template.
- **Zoneless Change Detection**: The app operates with `provideZonelessChangeDetection()`. State updates rely on **Signals** (`signal()`, `computed()`, `effect()`).
- **Signal-based component APIs (mandatory)**: Use the signal APIs instead of decorators:
  - Inputs: `input()` / `input.required()` (not `@Input()`).
  - Two-way: `model()` (not `@Input()` + `@Output()` pairs).
  - Outputs: `output()` (not `@Output()` + `EventEmitter`).
  - Queries: `viewChild()` / `viewChildren()` / `contentChild()` / `contentChildren()` (not the `@ViewChild`/`@ContentChild` decorators).
  - Declare `signal()` / `computed()` as **class fields**, created once. Never create a signal or computed inside a method — a new instance per call silently breaks reactivity.
  - Use `computed()` for derived state; do not mirror derivable state into extra writable signals. Reserve `effect()` for side effects (DOM, logging, non-signal sync), never to set other signals.
- **Async data**: Prefer `httpResource()` / `resource()` for declarative reactive data fetching where it fits; otherwise use the gateway API service with `toSignal()`. Keep RxJS for genuine event/stream pipelines.
- **Dependency Injection**: Use functional injection with `inject(Service)`. Do not use constructor parameter injection.
- **Component authoring rules (mandatory)**:
  - Use the `host` object in the decorator for host bindings/listeners. Do not use `@HostBinding` / `@HostListener`.
  - Bind classes and styles with `[class.x]` / `[style.x]` (or `[class]` / `[style]` with an object). Do not use `ngClass` / `ngStyle`.
  - Mark template-only members `protected` and injected/constant members `readonly`.
  - Keep templates and styles in separate `.html` / `.scss` files for non-trivial components; inline only for tiny presentational components.
  - Use `NgOptimizedImage` (`ngSrc`) for all static raster images.
- **Routing**: Standalone route configs only. Lazy-load feature routes with `loadComponent` / `loadChildren`. Guards, resolvers, and interceptors are functional (not class-based).
- **Import Path Rules** (strict order of preference):
  1. **Same directory** (`./`): When the target file is in the same folder, use `./` relative import. Example: `import { AccountsService } from './accounts.service';`
  2. **One level up** (`../`): When the target is in the immediate parent folder, use `../`. Example: `import { AuthService } from '../auth';`
  3. **Deeper ancestors** (`@app/`): For anything two or more levels up, use the `@app/*` path alias. Example: `import { UserModel } from '@app/data/models/user';`
  4. **Barrel files (index.ts)**: When a folder has an `index.ts` that re-exports its contents, import from the folder path (no file name). Example: `import { AuthService } from '../auth'` instead of `import { AuthService } from '../auth/auth.service'`.
  5. **Other aliases**:
     - `@assets/*` -> `./src/assets/*`
     - `@env/*` -> `./src/environments/*`
  - Never mix alias and relative for the same depth; consistency within a file is mandatory.

---

## UI & Styling (CoreUI + Bootstrap 5 + `ds-*`)

The application uses one layered visual system, shared by every CLASS Angular
app, defined by the **`coreui-styling`** skill (canonical spec + reference
SCSS). **Tailwind is not part of it** — it was removed. Do not add it, do not
use its utility classes.

- **CoreUI (`@coreui/angular` + `@coreui/coreui`)** is the structural
  foundation for the application shell: sidebar, header, footer, navigation,
  shell containers, responsive behavior, and color mode.
- **Bootstrap 5** (grid, utilities, form controls) is the layout and spacing
  layer for page content.
- **Tokens `--ds-*`** (`src/styles/_tokens.scss`) are the single source of
  every color, surface, border, radius, shadow, and font — nothing visual is
  hardcoded.
- **`ds-*` classes** (`_ds-components.scss`, `_ds-forms.scss`) and
  **`layout/shared` components** provide the established patterns: cards,
  panels, KPI cards, grids, tables, forms, badges, alerts, loading, empty
  states, modals.

For the full element-level spec (tokens, sizes, component APIs, `ds-*`
inventory, dark-mode contract) load the **`coreui-styling`** skill and read its
bundled `design-system.md`.

### Authoritative sources

1. **`coreui-styling` skill** → `design-system.md` (the written spec) and
   `reference/styles/` (canonical `_tokens.scss` / `_ds-components.scss` /
   `_ds-forms.scss` / `_theme.scss` — a project's four files must match these)
2. **CoreUI docs**: https://coreui.io/bootstrap/docs/getting-started/introduction/
3. **Project overrides**: `src/styles/custom/_<feature>.scss`, and
   `docs/design_ui.md` (pointer + documented exceptions only)

### Rules

- Use `@coreui/angular` components for the layout shell (sidebar, header,
  container, footer) — follow `src/app/layout/`.
- Use Bootstrap grid + utilities + `ds-*` for page composition, per the
  `coreui-styling` spec. Never Tailwind, never a second utility system.
- Reuse `layout/shared` components (`PageHeader`, `FilterBar`, `UiCard`,
  `StatCard`, `ChartCard`, `StatusBadge`, `EmptyState`, `UiSkeleton`, …) and
  `ds-*` classes before writing anything new.
- All colors, surfaces, borders, radii, shadows and fonts come from `--ds-*`
  tokens. No hardcoded `#fff` / `#111` / `black` / `white` / `.text-dark` /
  `.text-white`, no per-component `font-family` or px `font-size` override.
- Do not combine Bootstrap and `ds-*` to control the same visual property on
  the same element without a documented reason.
- Keep `_tokens.scss` / `_ds-components.scss` / `_ds-forms.scss` / `_theme.scss`
  byte-identical to `coreui-styling/reference/styles/`; change them there, then
  sync — never fork the palette per project.
- Use Font Awesome (`fas` / `fab`) for all icons — navigation, shell, and page
  content. No Lucide / Tabler.
- Charts: ApexCharts via the shared wrapper (see `design-system.md` §22).
- Custom CSS belongs in `src/styles/custom/_<feature>.scss` (via `_custom.scss`)
  or `_theme.scss` — never loose global SCSS under `src/app/`, avoid inline
  styles for static layout.

---

## Testing Guidelines (Vitest)

- Use **Vitest** (`vitest`) as the unit testing framework.
- Follow the **Arrange-Act-Assert (AAA)** convention for unit tests.
- Explicitly name test variables (`inputX`, `mockX`, `actualX`, `expectedX`).
- Write unit tests for all public services, repositories, and components.
- Use test doubles/mocks for external dependencies and HTTP requests (`provideHttpClientTesting`).
- Assert on signal values by calling the signal (`expect(component.total()).toBe(...)`); trigger change detection with `fixture.detectChanges()` under zoneless.
