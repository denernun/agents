# Layout shared UI (`app/layout/shared`)

Componentes do design system (CoreUI + `ds-*`) ficam nesta pasta.

Documentacao unica: skill **coreui-styling** no AgentHub --- `design-system.md`
(spec, sec. 11 e 51) + `reference/styles/` (SCSS canonico). Junction em
`.claude/skills/coreui-styling/`.

Import:

```typescript
import { PageHeaderComponent, UiCardComponent } from '@app/layout/shared';
```

**Cards com abas:** use `ds-tab-panel--fixed-grid` no painel (10 linhas de grid + paginação). Trocar de aba não pode redimensionar o card — ver Controle de Caixa.
