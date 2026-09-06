# Design UI --- CoreUI (canonical)

Documento **unico** de referencia de layout e design system dos front-ends
Angular das familias CLASS (ERPCLASS, NFECLASS, SHOPCLASS, MOBICLASS,
CRMCLASS). Vive no AgentHub (`D:\AGENTS\skills\coreui-styling\design-system.md`)
e chega a cada projeto pela skill `coreui-styling`.

> **Fonte unica.** Nada aqui e especifico de um produto nem ligado a um
> projeto: sao regras de elementos (cards, grids, botoes, tabelas, badges,
> formularios), tamanhos, cores, tipografia e comportamento. O estilo foi
> destilado uma vez a partir do `erpclass-dash` e agora vive aqui. A
> **referencia concreta** e o SCSS canonico em
> [`reference/styles/`](reference/) (`_tokens.scss`, `_ds-components.scss`,
> `_ds-forms.scss`, `_theme.scss`) --- os quatro arquivos de cada projeto
> devem ser **byte-identicos** a esses. Divergencia de estilo entre projetos e
> defeito a corrigir, nao escolha.
>
> O `docs/design_ui.md` de cada projeto, se existir, e **apenas um ponteiro**
> para esta skill mais eventuais excecoes documentadas --- nunca uma copia da
> especificacao, nunca um link para outro projeto. Editar o design system =
> editar esta skill (spec + `reference/styles/`) e sincronizar o SCSS nos
> projetos.

## 1. Objetivo

Modernizar a interface administrativa utilizando:

- **CoreUI** (`@coreui/angular` + `@coreui/coreui`) como base estrutural,
  shell e componentes administrativos.
- **Bootstrap 5** (grid, utilities, form controls) como camada de
  composicao visual.
- **Tokens `--ds-*`** (`src/styles/_tokens.scss`) e **classes `ds-*`**
  (`_ds-components.scss`, `_ds-forms.scss`) como identidade visual propria.
- **Angular + TypeScript** (standalone, zoneless, signals) como stack
  principal.
- **ApexCharts** (`ng-apexcharts`) para graficos, atraves do wrapper
  compartilhado, quando o app tiver graficos.
- **Font Awesome** (`fas` / `fab`) para icones.

A ideia nao e substituir o CoreUI. O objetivo e criar uma camada visual
propria sobre ele, reduzindo a aparencia generica de template
administrativo.

### Principio principal

> CoreUI controla a estrutura e o comportamento dos componentes.
> Bootstrap 5 + tokens `--ds-*` controlam o acabamento visual.
> `layout/shared` transforma essa combinacao em uma identidade unica.

---

# 2. Resultado visual desejado

A aplicacao devera seguir uma estetica:

- SaaS moderno
- clean
- bastante espaco em branco
- cards com bordas suaves
- sombras discretas
- tipografia moderna
- poucas cores de destaque
- estados visuais claros
- responsividade real
- suporte a dark mode desde o inicio
- componentes consistentes entre todas as telas **e entre todos os apps**

Referencia conceitual:

```text
+-------------------------------------------------------------+
| Logo       Busca global              Notificacoes   Usuario |
+--------------+--------------------------------------------- -+
|              | Titulo da pagina                             |
| Item 1       | Subtitulo / descricao                        |
| Item 2       |                                              |
| Item 3       | [ KPI ] [ KPI ] [ KPI ] [ KPI ]              |
| Item 4       |                                              |
|              | +--------------------+ +-------------------+ |
| GRUPO        | |                    | |                   | |
| Item 5       | |   Grafico / painel | | Grafico / painel  | |
| Item 6       | |                    | |                   | |
| Item 7       | +--------------------+ +-------------------+ |
|              |                                              |
|              | +--------------------+ +-------------------+ |
| GRUPO        | | Tabela             | | Ranking / lista   | |
| Item 8       | |                    | |                   | |
|              | +--------------------+ +-------------------+ |
| Configuracoes|                                              |
+--------------+----------------------------------------------+
```

---

# 3. Paleta visual

## 3.1 Cores principais

Fonte da verdade: `src/styles/_tokens.scss`. Todo valor visual vem de um
token `--ds-*`; nada de cor, superficie ou sombra em hex solto nas telas.

| Token             | Valor (light) | Uso                    |
| ----------------- | ------------- | ---------------------- |
| `--ds-background` | `#f0f4f8`     | Fundo geral da pagina  |
| `--ds-surface`    | `#ffffff`     | Cards e superficies    |
| `--ds-surface-muted`  | `#f1f5f9` | Areas secundarias      |
| `--ds-surface-header` | `#f8fafc` | Cabecalhos de painel   |
| `--ds-border`     | `#e2e8f0`     | Bordas                 |
| `--ds-text`       | `#1e293b`     | Texto principal        |
| `--ds-text-muted` | `#64748b`     | Texto secundario       |
| `--ds-primary`    | `#6366f1`     | Acoes principais       |
| `--ds-primary-hover` | `#4f46e5`  | Hover da primaria      |
| `--ds-primary-soft`  | `rgb(99 102 241 / .12)` | Fundo suave da primaria |
| `--ds-success`    | `#10b981`     | Sucesso                |
| `--ds-info`       | `#3b82f6`     | Informacao             |
| `--ds-warning`    | `#f59e0b`     | Atencao                |
| `--ds-danger`     | `#ef4444`     | Erro                   |

## 3.2 Tokens de superficie / tint / gradiente

Ja definidos no `_tokens.scss` (light e dark). Nao criar variantes paralelas.

- **Tints** (`--ds-<cor>-50 / -100 / -200`): fundos suaves de card e badge.
- **Gradientes de card** (`--ds-gradient-<cor>`): fundo diagonal claro -> surface.
- **Gradientes de header** (`--ds-gradient-header-<cor>`): cabecalho de painel/grafico.
- **Ranking** (`--ds-rank-gold/silver/bronze` + `-bg`): posicoes 1/2/3.
- **Sombras coloridas** (`--ds-shadow-<cor>`): realce de KPI `hero`.
- **Campos** (`--ds-input-bg`, `--ds-input-text`, `--ds-input-placeholder`,
  `--ds-field-text`), **kbd** (`--ds-kbd-*`) e **tags** (`--ds-tag-*`).

## 3.3 Regra de utilizacao

A cor primaria nao deve dominar a interface.

Usar `primary` principalmente em:

- botao principal
- item ativo da sidebar
- links importantes
- indicadores
- graficos
- foco de campos
- elementos selecionados

Evitar transformar todos os titulos, bordas e icones em roxo.

---

# 4. Tipografia

Fonte: token `--ds-font-sans` -> `'Inter', system-ui, -apple-system, sans-serif`.
Aplicada globalmente no `body`. **Nunca** sobrescrever `font-family` ou
definir `font-size` em px em componente isolado.

Escala real usada pelo design system (`_ds-components.scss`):

| Elemento                | Tamanho    | Peso |
| ----------------------- | ---------- | ---- |
| Titulo da pagina        | `1.75rem`  | 700  |
| Subtitulo da pagina     | `0.875rem` | 400  |
| Titulo de painel        | `0.9375rem`| 600  |
| Subtitulo de painel     | `0.75rem`  | 400  |
| Valor de KPI            | `1.5rem`   | 700  |
| Label de KPI            | `0.6875rem`| 600 (uppercase, `letter-spacing .06em`) |
| Texto de tabela (td)    | `0.875rem` | 400  |
| Cabecalho de tabela (th)| `0.6875rem`| 600 (uppercase, `letter-spacing .05em`) |
| Badge                   | `0.6875rem`| 700  |
| Label de formulario     | `0.8125rem`| 600  |

Pesos: Regular 400 / Medium 500 / Semibold 600 / Bold 700.

---

# 5. Espacamento

Escala baseada em Bootstrap 5 (multiplos de `0.25rem`):

```text
4px  8px  12px  16px  20px  24px  32px  40px  48px
```

Regra pratica:

- conteudo interno de card: `1.25rem` (`ds-panel__body`)
- distancia entre cards / grid gap: `1rem`
- distancia entre secoes: `1.5rem` (`margin-bottom` dos grids)
- titulo e subtitulo: `0.25rem–0.375rem`
- elementos de formulario: `0.5rem–0.75rem` (`row g-3`)

Preferir utilities Bootstrap (`gap-*`, `mb-*`, `p-*`) a CSS proprio.

---

# 6. Border Radius

Tokens (`_tokens.scss`):

```text
--ds-radius-card:   0.75rem   (12px)  -> cards, paineis, modais
--ds-radius-button: 0.5rem    (8px)   -> botoes
--ds-radius-input:  0.375rem  (6px)   -> inputs, selects, dropdown, alert
9999px  -> badges, pills, chips, segment control
```

Nao misturar muitos raios diferentes na mesma tela. Cantos de card e de
input sempre pelos tokens; nunca `border-radius` avulso em painel.

---

# 7. Sombras

Discretas. Tokens:

```text
--ds-shadow-card:        0 1px 3px 0 rgb(15 23 42 / .08)   (dark: /.35)
--ds-shadow-card-hover:  0 4px 12px 0 rgb(15 23 42 / .10)  (dark: /.40)
```

Hover de card/painel troca `--ds-shadow-card` -> `--ds-shadow-card-hover`
(via `.ds-panel:hover`, `.ds-stat-card:hover`, `.ds-hover-lift`).

Evitar sombras fortes (`shadow-lg` / `shadow-xl` do Bootstrap) na maioria
dos componentes administrativos. A intencao e uma interface leve, nao
"flutuante". Sombras coloridas (`--ds-shadow-<cor>`) so no KPI `hero`.

---

# 8. Arquitetura da aplicacao

Clean Architecture + CoreUI, com design system em `layout/shared`.
Estrutura padrao dos apps Angular ERPCLASS:

```text
src/app/
|
├── auth/                      # Autenticacao (signin, signup, reset, confirm,
|                              # magic-link, otp, ...) + guards/resolvers
|
├── data/                      # Dominio + acesso a dados
|   ├── models/                # interfaces de dominio
|   ├── repository/            # BaseRepository + FactoryRepository
|   └── services/              # servicos de dados (CRUD / API domain)
|
├── gateway/                   # Infra de comunicacao
|   ├── api/                   # HTTP + interceptors
|   └── socket/                # WebSocket
|
├── layout/                    # Shell + design system + helpers de UI
|   ├── default-layout/        # sidebar, header, footer, nav-items
|   ├── helpers/               # helpers de UI (periodo, tracking, ...)
|   └── shared/                # DS (CoreUI + ds-*)
|       ├── primitives/        # ui-button, ui-card, ui-modal,
|       |                      # ui-dropdown, ui-skeleton
|       ├── layout/            # page-header, filter-bar, period-segment
|       ├── data-display/      # stat-card, chart-card, status-badge,
|       |                      # empty-state, insight-alert, data-table,
|       |                      # table-cell-text, table-pagination
|       └── tokens/            # UiAccentColor, mappers de status, page size
|
├── pages/                     # Telas do produto (uma pasta por feature)
|
├── shared/                    # Utilitarios transversais (nao-UI)
|   ├── directives/
|   ├── pipes/
|   ├── utils/
|   ├── validators/
|   └── shared.module.ts
|
├── services/                  # Servicos de aplicacao
|   ├── alert/, toast/, spin/
|   ├── device/, events/
|   ├── storage/, mask/
|   └── translate/
|
├── error/                     # Pagina / handler de erro
|
├── app.ts / app.html
└── app.routes.ts
```

### Rotas (resumo)

- Shell autenticado (`DefaultLayoutComponent`): telas do produto sob
  `pages/`.
- Auth (fora do shell): `signin`, `signup`, `reset`, `confirm`, ...
- `error` + fallback `**`.

### Onde colocar codigo novo

| Tipo                          | Pasta                       |
| ----------------------------- | --------------------------- |
| Tela / feature do produto     | `pages/<feature>/`          |
| Componente do design system   | `layout/shared/...`         |
| Helper de UI / periodo        | `layout/helpers/`           |
| Shell (header/sidebar)        | `layout/default-layout/`    |
| Model / repository / data svc | `data/`                     |
| HTTP / socket                 | `gateway/`                  |
| Pipe, directive, validator    | `shared/`                   |
| Toast, spin, translate        | `services/`                 |

Import do design system:

```typescript
import { PageHeaderComponent, UiCardComponent } from '@app/layout/shared';
```

---

# 9. Responsabilidade de cada camada

## CoreUI

Usar CoreUI principalmente para:

- layout administrativo
- sidebar
- navbar
- modal
- dropdown
- tabelas
- formularios
- navegacao
- componentes estruturais
- comportamento responsivo quando ja fornecido

## Bootstrap 5

Usar Bootstrap para:

- spacing / padding / margin
- grid / flex
- typography (utilities)
- cores (utilities de apoio)
- borders / radius / shadows
- responsive
- estados
- dark mode (variaveis CoreUI)
- pequenas animacoes

## CSS proprio (`ds-*` e `custom/`)

Criar CSS proprio somente quando:

- o componente CoreUI exigir customizacao especifica
- Bootstrap nao resolver adequadamente
- existir comportamento visual global
- houver necessidade de tokens ou estilos complexos

Padroes reutilizaveis vao para `_ds-components.scss` / `_ds-forms.scss`.
Estilo de dominio vai para `src/styles/custom/_<feature>.scss` (via
`_custom.scss`). Evitar CSS especifico para cada tela.

---

# 10. Regra de ouro para CoreUI

Evitar:

```html
<div class="card p-4 bg-white shadow-lg border ..."></div>
```

quando isso provocar conflito de responsabilidades.

Preferir encapsular:

```html
<app-stat-card title="Faturamento" value="R$ 48.920,00" [variation]="12.4" variationLabel="vs mes anterior" />
```

O componente `app-stat-card` decide internamente como combinar CoreUI +
Bootstrap + tokens.

---

# 11. Design System

Criar componentes reutilizaveis antes de remodelar dezenas de telas.
Todos os componentes vivem em `src/app/layout/shared/` e sao importados
de `@app/layout/shared`.

## 11.1 Page Header --- `app-page-header`

Titulo, subtitulo, icone e slot de acoes.

| Input      | Tipo                | Default |
| ---------- | ------------------- | ------- |
| `title`    | `string` (required) | ---     |
| `subtitle` | `string?`           | ---     |
| `icon`     | `string?` (classe FA) | ---   |

Slot: `[pageHeaderActions]`. Classe: `.ds-page-header` (borda inferior em
gradiente `primary -> info`, titulo `1.75rem/700`, icone `2.75rem`).

```html
<app-page-header title="Contatos" subtitle="Base comercial da conta" icon="fas fa-address-book">
  <button pageHeaderActions class="btn btn-primary" type="button">Novo</button>
</app-page-header>
```

## 11.2 Stat Card --- `app-stat-card`

KPI com icone de acento, valor, chip de variacao e sparkline opcional.

| Input            | Tipo                                            | Default     |
| ---------------- | ----------------------------------------------- | ----------- |
| `title`          | `string` (required)                             | ---         |
| `value`          | `string` (required)                             | ---         |
| `subtitle`       | `string?`                                       | ---         |
| `variation`      | `number?` (percentual; sinal define up/down)    | ---         |
| `variationLabel` | `string?`                                       | ---         |
| `icon`           | `string?` (classe FA)                            | ---         |
| `color`          | `'primary' \| 'success' \| 'info' \| 'warning' \| 'danger' \| 'neutral'` | `'primary'` |
| `variant`        | `'default' \| 'hero' \| 'metric'`               | `'default'` |
| `loading`        | `boolean`                                       | `false`     |
| `sparkline`      | `readonly number[]`                             | `[]`        |

Classes: `.ds-stat-card` (+ `--<cor>`, `--hero`, `--metric`). `min-height`
`8.5rem` (`hero` `7.5rem`, `metric` `8.25rem`). Icone `3rem`, raio
`0.875rem`, fundo `--ds-accent-soft`.

> **Padronizacao:** KPIs de dashboard usam `variant="hero"` dentro de
> `ds-kpi-grid ds-kpi-grid--N`. **Nao** usar faixa/topo colorido em cima
> do card; o realce e o proprio fundo do `hero`.

## 11.3 Filter Bar --- `app-filter-bar`

Painel de filtros com header titulado. Renderiza um `.ds-panel
.ds-filter-panel` com `.row.g-3` no corpo (colunas `col-md-*` como
conteudo projetado).

| Input     | Tipo      | Default     |
| --------- | --------- | ----------- |
| `label`   | `string`  | `'Filtros'` |
| `loading` | `boolean` | `false`     |

Deve funcionar em desktop e mobile (as colunas colapsam pelo grid).

## 11.4 Status Badge --- `app-status-badge`

Pill de status padronizado (`.ds-badge` + `.ds-badge--*`).

| Input   | Tipo                | Default     |
| ------- | ------------------- | ----------- |
| `label` | `string` (required) | ---         |
| `color` | `UiAccentColor`     | `'neutral'` |

Paleta **unica** (light e dark iguais) --- fundo solido + texto branco:

| Variante  | Fundo     | Borda     | Uso tipico            |
| --------- | --------- | --------- | --------------------- |
| `danger`  | `#dc2626` | `#b91c1c` | Vencido / erro        |
| `warning` | `#d97706` | `#b45309` | Vencendo / aberto     |
| `info`    | `#2563eb` | `#1d4ed8` | A vencer / neutro-azul|
| `success` | `#059669` | `#047857` | Liquidado / ativo     |
| `primary` | `#4f46e5` | `#4338ca` | Destaque              |
| `neutral` | `#475569` | `#334155` | Inativo / n/a         |

Nunca criar badges manuais (`badge bg-success` etc.) nas telas migradas.
Nunca re-tintar badge por tema (regride contraste). Para mapear status de
API -> acento, usar os helpers de `layout/shared/tokens`.

## 11.5 Data Table --- `app-ui-data-table`

Wrapper de tabela (`table.ds-table` dentro de um `ds-panel`/`app-ui-card`).

| Input        | Tipo      | Default |
| ------------ | --------- | ------- |
| `alignMiddle`| `boolean` | `true`  |
| `fixedRows`  | `boolean` | `true`  |

Regras (canonicas):

- **10 linhas por pagina** --- `DS_TABLE_PAGE_SIZE` de `@app/layout/shared`.
- `th`: `padding .75rem 1.25rem`, uppercase `.6875rem/600`, fundo
  `--ds-gradient-header-primary`, borda inferior `2px`.
- `td`: `padding .75rem 1.25rem`, `--ds-text`, borda `1px --ds-border`.
- `--fixed-rows`: altura de linha fixa `2.75rem` (sem texto multi-linha).
- Hover de linha: fundo `--ds-primary-50`.
- Texto de celula: `app-ui-table-cell-text` (linha unica, ellipsis,
  valor completo no `title`).
- Paginacao: rodape `ds-panel__footer--pagination` (ou
  `app-ui-table-pagination`) sempre visivel quando ha dados ---
  "Anterior / Proximo" + "pagina X de Y".

Proibido em grids: `<br>` em celula, quebra de descricao longa, altura de
linha variavel.

## 11.6 Chart Card --- `app-chart-card`

Card de grafico: `ds-panel` com header (titulo + icone + subtitulo) e
corpo `ds-panel__body--chart` (`min-height 18rem`).

| Input      | Tipo                | Default |
| ---------- | ------------------- | ------- |
| `title`    | `string` (required) | ---     |
| `subtitle` | `string?`           | ---     |
| `icon`     | `string?`           | ---     |
| `loading`  | `boolean`           | `false` |

## 11.7 Ui Card --- `app-ui-card`

Container generico (painel / superficie).

| Input       | Tipo      | Default |
| ----------- | --------- | ------- |
| `title`     | `string?` | ---     |
| `subtitle`  | `string?` | ---     |
| `icon`      | `string?` | ---     |
| `noPadding` | `boolean` | `false` |

Slots de rodape: `[uiCardFooter]`.

## 11.8 Ui Button --- `app-ui-button`

Botao do DS sobre `.btn` do Bootstrap.

| Input     | Tipo                                                                                 | Default     |
| --------- | ----------------------------------------------------------------------------------- | ----------- |
| `variant` | `'primary' \| 'secondary' \| 'success' \| 'danger' \| 'warning' \| 'info' \| 'outline-primary' \| 'outline-secondary' \| 'outline-success' \| 'outline-danger' \| 'link'` | `'primary'` |
| `size`    | `'sm' \| 'md' \| 'lg'`                                                              | `'md'`      |
| `type`    | `'button' \| 'submit' \| 'reset'`                                                   | `'button'`  |
| `icon`    | `string?`                                                                           | ---         |
| `disabled`| `boolean`                                                                           | `false`     |
| `loading` | `boolean`                                                                           | `false`     |
| `block`   | `boolean`                                                                           | `false`     |

Botoes solidos (`btn-primary/secondary/success/danger/warning/info`)
recebem texto **branco, bold, uppercase** via `custom/_buttons.scss`.
Raio pelo token `--ds-radius-button`. Foco: `.ds-focus-ring`.

## 11.9 Ui Modal --- `app-ui-modal`

Modal presentacional (`.ds-modal*`). `max-width 32rem`, header/footer com
fundo `--ds-surface-header`.

| Input            | Tipo                | Default |
| ---------------- | ------------------- | ------- |
| `title`          | `string` (required) | ---     |
| `closeOnBackdrop`| `boolean`           | `true`  |

## 11.10 Ui Dropdown --- `app-ui-dropdown`

Dropdown (ngx-bootstrap). Menu: `.ds-dropdown__menu`.

| Input       | Tipo                                                                    | Default              |
| ----------- | --------------------------------------------------------------------- | -------------------- |
| `label`     | `string` (required)                                                  | ---                  |
| `icon`      | `string?`                                                            | ---                  |
| `variant`   | `'outline-secondary' \| 'outline-primary' \| 'primary' \| 'secondary'` | `'outline-secondary'` |
| `placement` | `string`                                                             | `'bottom left'`      |

## 11.11 Empty State --- `app-empty-state`

| Input         | Tipo                | Default          |
| ------------- | ------------------- | ---------------- |
| `title`       | `string` (required) | ---              |
| `description` | `string?`           | ---              |
| `icon`        | `string`            | `'fas fa-inbox'` |
| `actionLabel` | `string?`           | ---              |

Classe `.ds-empty` (icone `3.5rem`, centrado). Nunca deixar apenas
"Nenhum registro.".

## 11.12 Insight Alert --- `app-insight-alert`

Alerta informativo em card (`.ds-insight-alert` + `--<tom>`).

| Input         | Tipo                | Default              |
| ------------- | ------------------- | -------------------- |
| `title`       | `string` (required) | ---                  |
| `text`        | `string` (required) | ---                  |
| `icon`        | `string`            | `'fas fa-circle-info'` |
| `tone`        | `UiAccentColor`     | `'info'`             |
| `actionLabel` | `string?`           | ---                  |

## 11.13 Ui Skeleton --- `app-ui-skeleton`

| Input     | Tipo                                        | Default  |
| --------- | ------------------------------------------- | -------- |
| `variant` | `'text' \| 'card' \| 'circle' \| 'chart'`   | `'text'` |
| `height`  | `number` (px, variant `text`)               | `16`     |
| `size`    | `number` (px, variant `circle`)             | `40`     |

Animacao `ds-pulse` (ou `ds-skeleton--shimmer`). Substitui
`ngx-skeleton-loader` / `ngx-loading`.

## 11.14 Period Segment --- `app-period-segment`

Segment control de periodo (`.ds-segment` / `.ds-segment__btn`).

| Input       | Tipo                            | Default      |
| ----------- | ------------------------------- | ------------ |
| `options`   | `readonly PeriodSegmentOption[]`| padrao       |
| `active`    | `string`                        | `'day'`      |
| `ariaLabel` | `string`                        | `'Periodo'`  |

---

# 12. Layout principal

```text
MainLayout (DefaultLayoutComponent)
├── Sidebar
├── Header
└── Content
    ├── PageHeader
    └── RouterOutlet
```

## Dimensoes

```text
Header:  4rem + 1px  (fixo; .sidebar-header e .header > .container-fluid)
Sidebar: largura padrao do CoreUI
Sidebar recolhida: sidebar-narrow-unfoldable do CoreUI
Content: restante (.wrapper com padding-inline = sidebar-occupy)
Footer:  3rem + 1px
```

O shell (sidebar/header/footer/container) e **CoreUI** e nao deve ser
reimplementado com markup proprio.

---

# 13. Sidebar

## Estrutura

```text
LOGO (sidebar-brand)

GRUPO / SECAO
Item de navegacao
Item de navegacao
...

                      Configuracoes (rodape)
```

Itens definidos em `navItems: INavData[]` no `DefaultLayoutComponent`,
com `name`, `url` e `icon` (`fas fa-*` / `fab fa-*`).

## Visual

- Item normal: fundo transparente, texto `--cui-sidebar-nav-link-color`.
- Item ativo: destaque com `--ds-primary` (fundo suave + texto/icone
  primary), raio `--ds-radius-button`.
- Hover: fundo sutil (`--ds-surface-muted` equivalente do shell).

Nao usar fundo roxo forte em toda a linha.

---

# 14. Header

Componentes:

```text
[toggler] [Busca global ................]   [notificacoes] [tema] [tela cheia] [usuario]
```

Funcionalidades:

- menu mobile (sidebar toggler)
- busca global (`ds-search-field`, resultados em `ds-global-search__panel`)
- notificacoes
- dark mode (toggle CoreUI `ColorModeService`)
- tela cheia
- menu do usuario

A busca pode receber `Ctrl + K` (badge `.ds-kbd`) para abertura rapida.

---

# 15. Dashboard (tela de referencia)

A tela de dashboard e o exemplo de referencia do design system em cada app.

## Estrutura

```text
Page Header
Filters (opcional)
KPI Row          -> ds-kpi-grid ds-kpi-grid--N
Main Analytics   -> ds-dashboard-grid / --two / --hero
Secondary        -> ds-dashboard-grid--two / --three
Tables / Rankings
```

Grids (todos com `gap 1rem`, `margin-bottom 1.5rem`, filhos `height:100%`):

| Classe                        | Colunas (>= breakpoint)                         |
| ----------------------------- | ---------------------------------------------- |
| `ds-kpi-grid` (base)          | 1 / 2 (`576`) / 3 (`992`) / 7 (`1400`)         |
| `ds-kpi-grid--2 / --3 / --4 / --5` | 2 / 3 / 4 / 5 colunas conforme sufixo      |
| `ds-dashboard-grid`           | 1 / `2fr 1fr` (`1200`)                          |
| `ds-dashboard-grid--two`      | 1 / 2 (`992`)                                   |
| `ds-dashboard-grid--three`    | 1 / 3 (`1200`)                                  |
| `ds-dashboard-grid--hero`     | 1 / `2fr 1fr` (`1200`)                          |
| `ds-dashboard-grid--alerts`   | 1 / 2 (`768`) / 5 (`1400`)                      |

---

# 16. KPI Cards

Primeira linha: os KPIs mais relevantes do modulo (tipicamente 3--5).

Cada card possui:

- titulo (label uppercase)
- valor
- variacao percentual (chip up/down)
- comparacao (`variationLabel`)
- icone de acento
- mini grafico opcional (`sparkline`)

```html
<div class="ds-kpi-grid ds-kpi-grid--4">
  <app-stat-card
    variant="hero"
    title="..."
    value="..."
    icon="fas fa-..."
    color="success"
    [variation]="12.4"
    variationLabel="vs periodo anterior" />
</div>
```

---

# 17. Grafico principal (serie temporal)

Formato:

- line / area chart
- preenchimento suave abaixo da linha
- tooltip moderno
- grid discreto (`--ds-border`)
- poucos labels
- responsivo

Encapsular em `app-chart-card` + wrapper de grafico compartilhado
(ver secao 22).

---

# 18. Grafico de distribuicao (donut)

- donut chart
- total no centro
- legenda com percentual
- **no maximo 4 cores** (evitar excesso de cores)

---

# 19. Tabela de registros recentes

`app-ui-card` + `app-ui-data-table` com colunas do dominio, `StatusBadge`
para status e menu de acoes (`app-ui-dropdown` / `.` -> Visualizar,
Editar, ...). 10 linhas por pagina + rodape de paginacao.

---

# 20. Ranking

Ranking visual reutilizavel: posicao (`.ds-rank` / `--1/2/3`), rotulo
(`app-ui-table-cell-text`) e barra de proporcao
(`.ds-cell-progress` / `__bar` / `__fill--<cor>`).

```text
Item A     ################  35%
Item B     ###########       28%
Item C     ########          21%
```

---

# 21. Responsividade

Breakpoints Bootstrap 5: `576` / `768` / `992` / `1200` / `1400`.

## Desktop (>= 992)

Layout completo: Sidebar + Header + Grid.

## Tablet (768--991)

- Sidebar pode iniciar recolhida.
- `4 KPIs -> 2 colunas`; `2 graficos -> 1 por linha`.

## Mobile (< 768)

- Sidebar: drawer.
- KPI: 1 coluna.
- Filtros: colapsam (grid) ou drawer/modal.
- Tabela: scroll horizontal (container `overflow-x:auto`) ou cards.

O `body` da pagina **nunca** rola na horizontal.

---

# 22. Dark Mode

Implementar desde o inicio. Nao implementar tela por tela.

## Fonte da verdade do tema

O CoreUI `ColorModeService` grava o tema em:

```text
html[data-coreui-theme="light" | "dark"]
```

e dispara um evento customizado por app. Cada app registra seu proprio
`eventName` no `ColorModeService` (ex.: `crmclass-app` usa
`this.#colorModeService.eventName.set('<app>-colorScheme')`).

**Nao** decidir light/dark apenas por `body.c-dark-theme`:

- em `index.html` a classe pode existir de forma estatica;
- o toggle do header atualiza `data-coreui-theme`, nao necessariamente
  remove a classe do `body` sozinho.

Regra do projeto:

1. Detectar tema por `document.documentElement.dataset.coreuiTheme`.
2. Sincronizar `body.c-dark-theme` no `AppComponent` (effect) para
   tokens / CSS legado.
3. Tokens em `_tokens.scss` respondem a
   `html[data-coreui-theme='dark']` **e** `body.c-dark-theme`.

## Valores (de `_tokens.scss`)

| Token             | Light     | Dark      |
| ----------------- | --------- | --------- |
| `--ds-background` | `#f0f4f8` | `#1a1d24` |
| `--ds-surface`    | `#ffffff` | `#212631` |
| `--ds-surface-muted` | `#f1f5f9` | `#2a303c` |
| `--ds-border`     | `#e2e8f0` | `#3c4b64` |
| `--ds-text`       | `#1e293b` | `#e2e8f0` |
| `--ds-text-muted` | `#64748b` | `#9da5b1` |

## Graficos (ApexCharts)

Padrao canonico (o primeiro app a adicionar graficos cria estes arquivos;
os demais copiam desse) --- valido para quando o app adicionar graficos:

- Builder `dashboard-chart.theme.ts`: `theme.mode`, `foreColor`, grid,
  legend e tooltip seguem `data-coreui-theme`.
- Ordem de leitura dos tokens: em dark, `document.body` primeiro
  (`index.html` aplica `body.c-dark-theme` antes de `html` receber
  `data-coreui-theme`); em light, `document.documentElement` primeiro.
- Eixos / escalas: `--ds-text`. Legenda / titulo: `--ds-text-muted`.
  Grid: `--ds-border`.
- Wrapper `app-dashboard-apex-chart` reaplica cores ao ouvir o evento
  `<app>-colorScheme` (troca de tema sem reload).

Bug tipico a evitar: chart em `theme.mode='dark'` lendo `--ds-text` do
modo light -> texto escuro em fundo escuro (invisivel).

Todos os componentes do design system devem funcionar nos dois temas.

---

# 23. Estados dos componentes

Todo componente visual importante deve possuir:

- **Normal** (default)
- **Hover** (`ds-hover-lift`, `.ds-panel:hover`, ...)
- **Focus** (`.ds-focus-ring` / `.ds-focus-glow`, `outline 2px --ds-primary`)
- **Disabled** (opacidade + cor `--ds-text-muted`)
- **Loading** (skeleton)
- **Empty** (`app-empty-state`)
- **Error** (`ds-alert ds-alert--danger`)

---

# 24. Loading

Evitar spinner central para a pagina inteira. Preferir skeleton.

```text
app-ui-skeleton (variant="text" | "card" | "circle" | "chart")
```

Composicoes:

- KPI: `variant="card"` dentro do `ds-kpi-grid`.
- Grafico: `variant="chart"` (ou `.ds-skeleton--chart`, `min-height 16rem`).
- Tabela: linhas skeleton de altura fixa.

Nao usar `ngx-skeleton-loader` / `ngx-loading`.

---

# 25. Empty State

```text
        [icone]

Nenhum registro encontrado

Nao existem itens para os filtros selecionados.

        [Limpar filtros]
```

Sempre via `app-empty-state`. Nunca deixar so "Nenhum registro.".

---

# 26. Acessibilidade

Implementar:

- navegacao por teclado
- foco visivel (`.ds-focus-ring`, `.ds-focus-glow`; linhas clicaveis com
  `tabindex="0"` e outline no `:focus-visible`)
- cabecalhos de tabela ordenaveis acessiveis (`.ds-table__sortable`)
- labels em formularios
- contraste adequado (ver secao 22 / contrato de tipografia)
- `aria-label` quando necessario
- suporte a screen reader
- nao depender somente de cores para status (badge tem texto)
- tamanhos de clique adequados em mobile

---

# 27. Animacoes

Microinteracoes discretas. Duracoes padrao: `0.15s` (cor) e `0.2s`
(sombra / transform). Utilities do DS:

| Classe            | Efeito                                   |
| ----------------- | ---------------------------------------- |
| `ds-hover-lift`   | `translateY(-2px)` + sombra hover        |
| `ds-press`        | `scale(0.97)` no `:active`               |
| `ds-focus-glow`   | halo `0 0 0 3px rgb(99 102 241 / .25)`   |
| `ds-skeleton--shimmer` | gradiente animado de loading        |
| `ds-glow`         | pulso de destaque (notificacao)          |

Aplicacoes: hover de cards, sidebar, dropdown, modal, botoes, mudancas de
estado. Evitar animacoes exageradas --- o sistema deve parecer rapido.

---

# 28. Organizacao do CSS

Evitar dezenas de classes repetidas em todos os templates. Quando uma
combinacao se repetir, encapsular em componente `layout/shared` ou em
classe global `ds-*`.

Em vez de repetir `rounded border bg-white p-4 shadow-sm ...` em 30
lugares, usar `app-ui-card` / `ds-panel`.

---

# 29. Design Tokens

Fonte unica: `src/styles/_tokens.scss` (blocos light + dark). Nao
espalhar valores de identidade visual pela aplicacao e nao criar um
segundo sistema de tokens.

Grupos de tokens: cores base, `primary-hover/soft`, superficies,
`radius`, `shadow`, `font`, campos (`input`/`field`), `kbd`, `tag`,
tints (`-50/-100/-200`), gradientes de card e de header, ranking,
sombras coloridas.

Manter `_tokens.scss` (e `_ds-components.scss`, `_ds-forms.scss`,
`_theme.scss`) **byte-identicos ao `reference/styles/` desta skill** ---
mesmos nomes de variavel, mesmos blocos, mesmos valores. Alterar la e
sincronizar; nao bifurcar a paleta por projeto.

---

# 30. Estrategia de padronizacao

Nao tentar modernizar / alinhar tudo de uma vez.

## Fase 1 --- Fundacao

Tokens, tema, tipografia, cores, background, layout, sidebar, header,
dark mode base. Resultado: aplicacao inteira com a estrutura visual
padrao.

## Fase 2 --- Design System

Button, Card, Stat Card, Page Header, Filter Bar, Badge, Table, Modal,
Dropdown, Skeleton, Empty State, Chart Card, Insight Alert. Resultado:
componentes reutilizaveis conforme a secao 11 e o `reference/`.

## Fase 3 --- Dashboard

A tela de referencia: KPIs, filtros, graficos, tabela, ranking, loading,
empty state, responsividade.

## Fase 4 --- Primeira tela CRUD

Escolher uma tela de listagem simples e aplicar: Page Header, filtros,
tabela, status, acoes, modal, formulario, loading, empty state. Serve
para validar o design system.

## Fase 5 --- Demais modulos

Migrar progressivamente as telas restantes, sempre conforme esta
especificacao e os componentes `layout/shared` ja padronizados.

---

# 31. Ordem de implementacao recomendada

```text
01. Bootstrap 5 + CoreUI configurados
02. Design tokens (_tokens.scss)
03. Tema global (_theme.scss)
04. Tipografia
05. Main Layout
06. Sidebar
07. Header
08. Buttons
09. Cards
10. Form controls (ds-form-control / ds-select)
11. Badges
12. Page Header
13. Filters
14. Tables
15. Modal
16. Loading / Skeleton
17. Empty State
18. Dashboard
19. Primeira tela CRUD
20. Demais modulos
21. Dark Mode (revisao completa)
22. Refinamento
23. Acessibilidade
24. Performance
```

---

# 32. Criterios de aceitacao visual

Antes de considerar uma tela pronta:

### Layout

- [ ] Espacamento consistente
- [ ] Grid responsivo
- [ ] Sidebar funcionando
- [ ] Header funcionando
- [ ] Mobile funcionando

### Visual

- [ ] Tipografia consistente (escala da secao 4)
- [ ] Cores dentro da paleta (`--ds-*`)
- [ ] Border radius consistente (tokens)
- [ ] Sombras discretas
- [ ] Sem excesso de cores
- [ ] Sem excesso de bordas

### UX

- [ ] Loading / Empty state / Error state
- [ ] Hover / Focus / Disabled

### Acessibilidade

- [ ] Navegacao por teclado
- [ ] Labels
- [ ] Contraste
- [ ] Foco visivel

---

# 33. Performance

Evitar:

- carregar graficos pesados desnecessariamente
- componentes gigantes
- subscriptions sem cleanup
- chamadas duplicadas a API
- imagens sem necessidade
- bibliotecas duplicadas para a mesma funcao

Priorizar:

- lazy loading das features
- componentes reutilizaveis
- carregamento sob demanda
- cache quando aplicavel
- paginacao server-side em tabelas grandes
- debounce em pesquisas
- atualizacao incremental dos graficos

---

# 34. Arquitetura de tela com dados

Separar visualizacao e obtencao dos dados.

```text
FeatureComponent
       │
       ├── FeatureService ──── API
       │
       └── componentes visuais (apresentacao pura)
               ├── StatCard
               ├── ChartCard + grafico
               ├── UiDataTable
               └── ...
```

Evitar chamadas HTTP diretamente em cada componente visual.

---

# 35. Modelo de dados agregador

Para telas do tipo dashboard, criar um modelo agregador unico, para o
backend/API evoluir sem acoplar os componentes visuais.

```typescript
export interface DashboardData {
  summary: DashboardSummary;
  series: SeriesPoint[];
  distribution: DistributionSlice[];
  recent: RecordSummary[];
  ranking: RankingItem[];
}
```

---

# 36. Componentes visuais de uma feature

Estrutura:

```text
<feature>/
├── <feature>.component.ts / .html / .scss
├── components/
│   ├── <feature>-summary/
│   ├── <feature>-chart/
│   ├── <feature>-table/
│   └── ...
└── services/
    └── <feature>.service.ts
```

---

# 37. Responsabilidade dos componentes

- **Container** (`<feature>.component`): orquestra filtros, carregamento,
  dados e atualizacao.
- **Componentes visuais**: apenas apresentacao (KPI, grafico, tabela,
  ranking). Sem logica de negocio, sem HTTP.

Isso mantem o codigo simples e testavel.

---

# 38. Estrategia para tabelas

Para tabelas grandes:

```text
API -> paginacao -> filtro -> ordenacao -> resultado
```

Nao carregar milhares de registros no browser so para paginar
visualmente. `pageSize: DS_TABLE_PAGE_SIZE` no request; voltar para a
pagina 1 quando um filtro muda.

---

# 39. Estrategia para filtros

O filtro deve ser um objeto unico e centralizado:

```typescript
export interface FeatureFilters {
  startDate?: string;
  endDate?: string;
  [key: string]: unknown;
}
```

Facilita refresh, compartilhamento de URL, historico, persistencia e
testes.

---

# 40. URL como estado opcional

Para telas de consulta e relatorios, considerar espelhar os filtros na
URL:

```text
/feature?period=month&status=open
```

Beneficios: compartilhar consulta, voltar pelo navegador, refresh
mantendo filtros, bookmark.

---

# 41. Testes

Criar testes principalmente para:

- componentes do design system
- filtros
- formatacao / pipes
- estados
- permissoes
- tabelas
- servicos
- transformacao dos dados agregados

Nao e necessario testar cada classe Bootstrap. Testar comportamento.

---

# 42. Permissoes

O visual deve respeitar permissoes.

```text
Sem permissao de excluir:  [Visualizar] [Editar]
Com permissao:             [Visualizar] [Editar] [Excluir]
```

Nao confiar apenas na ocultacao visual --- a API tambem valida
autorizacao.

---

# 43. Checklist tecnico inicial

- [ ] Confirmar versao do Angular
- [ ] Confirmar versao do CoreUI
- [ ] Confirmar versao do Node / gerenciador de pacotes
- [ ] Verificar configuracao atual de CSS
- [ ] Verificar componentes CoreUI existentes
- [ ] Verificar conflitos CSS atuais
- [ ] Verificar biblioteca de graficos (ApexCharts)
- [ ] Verificar sistema de icones (Font Awesome)
- [ ] Verificar estrategia de temas (`ColorModeService`)
- [ ] Verificar build de producao

---

# 44. Estrategia para evitar conflitos CoreUI x Bootstrap

Antes de aplicar mudancas de estilo em toda a aplicacao:

1. criar / usar uma tela experimental;
2. aplicar o padrao somente nessa tela;
3. verificar estilos do CoreUI;
4. verificar componentes de formulario;
5. verificar modais;
6. verificar dropdowns;
7. verificar tabelas;
8. verificar build de producao;
9. so depois migrar o restante.

O objetivo e descobrir conflitos cedo.

---

# 45. Nao fazer

- substituir o shell CoreUI por markup proprio
- criar CSS gigante
- criar um componente diferente para cada tela
- usar Bootstrap para duplicar funcionalidades ja existentes no CoreUI
- instalar varias bibliotecas de componentes
- misturar varios sistemas de icones
- usar dezenas de cores
- colocar logica de negocio nos componentes visuais
- duplicar componentes
- copiar e colar classes visuais em dezenas de arquivos
- inventar paleta / tokens fora de `--ds-*`
- KPI card com faixa/topo colorido (usar `variant="hero"`)
- re-tintar badge por tema

---

# 46. Resultado arquitetural esperado

```text
                 APPLICATION
                      │
          ┌───────────┴───────────┐
       Layout                 Features
          │                       │
    ┌─────┴─────┐          ┌──────┴──────┐
 Sidebar      Header     Dashboard      CRUDs
    │           │
    └─────┬─────┘
       Design System
          │
 ┌────────┼─────────┐
Cards    Tables    Forms
 └────────┼─────────┘
          │
       CoreUI + Bootstrap 5 + tokens --ds-*
```

---

# 47. Plano de execucao em etapas

## Sprint 1 --- Fundacao

Tokens + tema + layout + sidebar + header + responsividade + dark mode base.

## Sprint 2 --- Design System

Button, Card, Stat Card, Badge, Page Header, Filter Bar, Input, Select,
Table, Modal, Skeleton, Empty State.

## Sprint 3 --- Dashboard

KPIs, filtros, graficos, tabela, ranking, loading, empty state,
responsividade.

## Sprint 4 --- Primeira migracao

Validar o design system em uma tela real (listagem + busca + filtros +
tabela + paginacao + cadastro + edicao + exclusao + validacoes + loading).

## Sprint 5 --- Migracao dos modulos

Migrar as telas restantes progressivamente.

## Sprint 6 --- Refinamento

Microinteracoes, dark mode completo, acessibilidade, performance,
responsividade, estados de erro, skeletons, revisao visual, limpeza de
CSS, padronizacao.

---

# 48. Definition of Done

Uma tela so e considerada pronta quando:

```text
[x] Layout novo
[x] Design system utilizado (layout/shared + ds-*)
[x] Responsiva
[x] Dark mode
[x] Loading
[x] Empty state
[x] Error state
[x] Hover
[x] Focus
[x] Acessibilidade basica
[x] Permissoes
[x] Performance validada
[x] Sem CSS duplicado
[x] Sem componente duplicado
```

---

# 49. Regra final do projeto

A principal decisao arquitetural e:

> Nao transformar Bootstrap / `ds-*` em mais um framework de componentes
> paralelo ao CoreUI.

Bootstrap 5 e os tokens `--ds-*` sao a ferramenta de composicao visual.
CoreUI continua responsavel pelo comportamento e pela estrutura
administrativa. O `layout/shared` transforma essa combinacao em uma
identidade visual unica --- **a mesma em todos os apps ERPCLASS**.

Assim o sistema deixa de parecer "um template CoreUI personalizado" e
passa a parecer "um sistema proprio construido sobre CoreUI".

---

# 50. Notas de implementacao --- tema, badges e graficos

Decisoes padrao para todos os apps CLASS.

## 50.1 Deteccao de tema (obrigatorio)

| Mecanismo                         | Papel                                      |
| --------------------------------- | ------------------------------------------ |
| `html[data-coreui-theme]`         | Fonte da verdade (CoreUI ColorModeService) |
| Evento `<app>-colorScheme`        | Notifica troca de tema                     |
| `body.c-dark-theme`               | Espelho sincronizado no `AppComponent`     |

Arquivos-chave: `src/app/app.ts` (sync `body.c-dark-theme` +
`eventName.set`), `src/styles/_tokens.scss` (tokens dual-theme),
`src/styles/_theme.scss` (shell), e o builder de tema dos graficos
quando existir.

## 50.2 Status badges

Classes em `_ds-components.scss` (`.ds-badge--*`). Light e dark usam a
**mesma** paleta solida (fundo escuro + texto branco). Componente:
`app-status-badge`. Nao sobrescrever badges por tema.

## 50.3 Graficos ApexCharts (quando o app tiver graficos)

- Builder `dashboard-chart.theme.ts` (`theme.mode`, `foreColor`, grid,
  legend, tooltip).
- Wrapper `app-dashboard-apex-chart` reaplica o tema no evento
  `<app>-colorScheme`.
- Validar sempre apos toggle light/dark: eixos e legendas legiveis;
  nomes de categoria em barra horizontal legiveis.
- Builders sempre em funcao `buildDashboard*ChartOptions()` --- sem
  config Apex inline no widget.

## 50.4 Checklist ao portar para outro projeto

```text
[ ] ColorModeService com eventName + localStorage proprios
[ ] Sync body.c-dark-theme a partir de data-coreui-theme
[ ] Tokens com selectors html[data-coreui-theme=dark] e body.c-dark-theme
[ ] Badges com contraste alto (paleta solida unica)
[ ] Charts leem data-coreui-theme (nao so body.c-dark-theme)
[ ] Charts reagem ao evento de troca de tema
```

---

# 51. Referencia pratica --- `layout/shared` e classes `ds-*`

Conteudo operacional do design system. Novos componentes de tema/layout
devem nascer em `src/app/layout/shared/`.

## 51.1 Organizacao de pastas

```text
src/app/layout/
  default-layout/   shell (sidebar, header, footer)
  helpers/          helpers de UI (periodo, tracking)
  shared/           design system (CoreUI + ds-*)
    primitives/     ui-button, ui-card, ui-modal, ui-dropdown, ui-skeleton
    layout/         page-header, filter-bar, period-segment
    data-display/   stat-card, chart-card, status-badge, empty-state,
                    insight-alert, data-table, table-cell-text, table-pagination
    tokens/         UiAccentColor, mappers de status, DS_TABLE_PAGE_SIZE
```

Import:

```typescript
import {
  PageHeaderComponent, FilterBarComponent, UiCardComponent, UiButtonComponent,
  StatCardComponent, ChartCardComponent, StatusBadgeComponent, EmptyStateComponent,
  UiSkeletonComponent, UiDataTableComponent, DS_TABLE_PAGE_SIZE,
} from '@app/layout/shared';
```

## 51.2 Componentes Angular

| Selector                  | Uso                                  |
| ------------------------- | ------------------------------------ |
| `app-page-header`         | Titulo + subtitulo + icone + acoes   |
| `app-filter-bar`          | Barra / painel de filtros            |
| `app-period-segment`      | Segment control de periodo           |
| `app-ui-card`             | Painel / superficie generica         |
| `app-ui-button`           | Botao do DS                          |
| `app-ui-modal`            | Modal presentacional                 |
| `app-ui-dropdown`         | Dropdown (ngx-bootstrap)             |
| `app-ui-skeleton`         | Loading skeleton                     |
| `app-ui-data-table`       | Wrapper `ds-table`                   |
| `app-ui-table-cell-text`  | Celula de texto (ellipsis + title)   |
| `app-ui-table-pagination` | Rodape de paginacao                  |
| `app-stat-card`           | KPI                                  |
| `app-chart-card`          | Card de grafico                      |
| `app-status-badge`        | Badge de status                      |
| `app-empty-state`         | Estado vazio                         |
| `app-insight-alert`       | Alerta informativo em card           |

Regra: nao duplicar estilos nos templates --- encapsular em
`layout/shared` ou em classes globais `ds-*`.

## 51.3 SCSS global

| Arquivo               | Conteudo                                              |
| --------------------- | ---------------------------------------------------- |
| `_tokens.scss`        | Variaveis CSS light/dark (SSOT)                       |
| `_ds-components.scss` | Paineis, KPIs, grids, tabelas, badges, ranking,      |
|                       | modal, dropdown, empty, alerts, skeleton, a11y,      |
|                       | microinteracoes                                     |
| `_ds-forms.scss`      | Inputs, ng-select, busca no header, kbd, paginacao   |
| `_theme.scss`         | Shell CoreUI (body, header, sidebar, footer)         |
| `styles.scss`         | Bootstrap 5 + CoreUI + imports do DS                 |
| `_custom.scss`        | Barrel de `custom/_<feature>.scss`                   |
| `custom/_*.scss`      | CSS por feature (ex.: `_auth-social.scss`)           |

### Formularios (`_ds-forms.scss`)

| Classe             | Uso                                              |
| ------------------ | ----------------------------------------------- |
| `ds-form-control`  | Inputs Bootstrap (`form-control`, `form-select`)|
| `ds-select`        | `ng-select` (container + tags + uppercase)      |
| `ds-select-panel`  | `panelClass` do ng-select (+ `appendTo="body"`) |
| `ds-input-group`   | Grupo com icone prefixo                         |
| `ds-search-field`  | Busca global no header                          |
| `ds-header-account`| Seletor de empresa no header                    |
| `ds-kbd`           | Badge de atalho (Ctrl+K)                        |

### Componentes (`_ds-components.scss`)

| Classe                        | Uso                                    |
| ----------------------------- | -------------------------------------- |
| `ds-panel` / `ds-panel__*`    | Superficie com header/body/footer      |
| `ds-stat-card` / `--<cor>` / `--hero` / `--metric` | KPI                |
| `ds-page-header`              | Cabecalho de pagina                    |
| `ds-kpi-grid` / `--2..--5`    | Grid de KPIs                           |
| `ds-dashboard-grid` / `--two` / `--three` / `--hero` / `--alerts` | Grids de conteudo |
| `ds-table` / `--fixed-rows` / `--striped` / `__sortable` | Tabelas         |
| `ds-badge--*`                 | Status (paleta unica light/dark)       |
| `ds-rank--1/2/3/default`      | Posicao de ranking                     |
| `ds-cell-progress__*`         | Barra de proporcao em celula           |
| `ds-empty__*`                 | Estado vazio                           |
| `ds-skeleton` / `--card` / `--chart` / `--shimmer` | Loading            |
| `ds-alert--danger/warning/success/info` | Feedback de API              |
| `ds-modal__*`                 | Shell de modal                         |
| `ds-dropdown__menu`           | Menu dropdown                          |
| `ds-insight-alert--*`         | Alerta informativo                     |
| `ds-segment` / `ds-segment__btn` | Segment control                    |
| `ds-focus-ring` / `ds-focus-glow` | Foco visivel                      |
| `ds-hover-lift` / `ds-press` / `ds-glow` | Microinteracoes             |

### Custom por feature

Estilos de dominio em `src/styles/custom/_<feature>.scss`, importados por
`_custom.scss`.

## 51.4 Template padrao de pagina

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

  <app-ui-card title="..." icon="fas fa-..." [noPadding]="true">
    <app-ui-data-table>
      <!-- thead / tbody -->
    </app-ui-data-table>
  </app-ui-card>
</div>
```

ng-select:

```html
<ng-select class="ds-select" panelClass="ds-select-panel" appendTo="body" ...></ng-select>
```

## 51.5 Checklist de tela migrada

```text
[ ] PageHeader + FilterBar (se houver filtros)
[ ] UiCard + UiDataTable / ds-table nas listagens
[ ] StatusBadge / EmptyState / UiSkeleton
[ ] ds-form-control nos inputs, ds-select nos ng-select
[ ] ds-alert em erros de API
[ ] KPIs com stat-card variant="hero" + ds-kpi-grid--N
[ ] Sem classes legadas (dashboard-kpi-*, ngx-skeleton-loader)
[ ] Dark/light validados (cards, badges, charts, forms)
[ ] Alinhado a esta especificacao (tokens, tamanhos, APIs dos componentes)
```

## 51.6 Proibido / depreciado

- Classes legadas: `dashboard-kpi-*`, `dashboard-panel`,
  `dashboard-table-card`
- `ngx-skeleton-loader` / `ngx-loading` --- usar `UiSkeletonComponent`
- `ngx-pagination` --- paginacao manual com
  `ds-panel__footer--pagination` / `app-ui-table-pagination`
- Inventar paleta / tokens fora de `--ds-*`
- Cor / superficie / fonte hardcoded (`#fff`, `#111`, `black`, `white`,
  `.text-dark`, `.text-white`, `font-family`, `font-size` em px)
- CSS solto sob `src/app/` (exceto estilo local inevitavel)
- Card com estilo proprio (`box-shadow` / `border` / `border-radius`
  avulso em painel)
- KPI card com faixa/topo colorido (usar `variant="hero"`)
- Re-tintar badge por tema
- Icones Lucide / Tabler --- usar Font Awesome (`fas` / `fab`)
- Chart.js --- usar ApexCharts
- Tailwind ou qualquer sistema de utilities paralelo para composicao de
  pagina --- usar grid Bootstrap + `ds-*`
