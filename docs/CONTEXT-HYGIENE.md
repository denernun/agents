# Higiene de contexto (agentes)

> ## AVISO — manter organizado
>
> Contexto **always-on gordo** = tokens desperdiçados em **toda** conversa.
> Guias NestJS / Angular completos vivem **somente** em `skills/` (on-demand).
> **Nunca** recolocar esses guias em `AGENTS.md`, `.cursorrules`, rules com `alwaysApply: true`,
> `.agents/rules/*.md`, `.kiro/steering/*.md` ou `copilot-instructions.md`.
> Edite no hub → `Install-AgentHub.ps1` → commit só o que for texto versionado (AGENTS enxutos).

## O que entra no contexto (e quando)

| Camada | Arquivos típicos | Quando carrega | Tamanho alvo |
|--------|------------------|----------------|--------------|
| **Always-on** | `AGENTS.md`, `.cursorrules`, ponteiros `.mdc`, Copilot slim, `.agents/rules/stack-pointer.md` (Antigravity), `.kiro/steering/stack-pointer.md` (Kiro) | Toda conversa no repo | **&lt; 2 KB** cada |
| **On-demand** | Skills em `.cursor/skills/*`, `.agents/skills/*`, `.kiro/skills/*`, `.opencode/skills/*`, `.claude/skills/*`, `.codex/skills/*`, `.devin/skills/*` (junction → hub; **Kiro = cópia**, ver Revisão 2026-09-18) | Só quando o agente abre a skill | OK 1–25 KB |
| **MCP** | `.cursor/mcp.json`, `.vscode/mcp.json`, `.kiro/settings/mcp.json`, `opencode.json` (raiz), `.agents/mcp_config.json`, `.mcp.json` (Claude Code), `.codex/config.toml`, `.devin/mcp_config.json` | Ferramentas MCP, não texto de guia | trio comum; mongodb+openapi nas APIs; playwright nos frontends (exceto Codex) |
| **Local only** | seção `## Local` do `AGENTS.md` | Always-on, mas só notas do repo | Curto |

## Skills no hub (on-demand — ok serem maiores)

| Skill | ~KB | Família |
|-------|-----|---------|
| `nestjs-clean-architecture` | 21 | NestJS |
| `angular-coreui` | 10 | Angular |
| `coreui-styling` | 14 + `design-system.md` 52 | Angular |
| `claude-android-ninja` | vendor | Android (junction → `vendor/claude-android-ninja`) |
| `codegraph` | 2 | nestjs/angular/android/minimal |
| `debug-issue` / `explore-codebase` / `refactor-safely` / `review-changes` | ~1 | processo |

> `coreui-styling/design-system.md` é a especificação escrita completa do design
> system (as 51 seções, antes garfadas em `docs/design_ui.md` de cada projeto).
> É **arquivo de referência**, aberto sob demanda pelo agente a partir do
> `SKILL.md` — não entra no contexto quando a skill só dispara. Fonte única:
> editar aqui no hub; chega a todos os projetos pelo junction da pasta da skill.
> Projetos **não** devem manter cópia própria nem apontar para `erpclass-dash`.

## Fonte canônica

- Edite skills **somente** em `D:\AGENTS\skills/`.
- Replique com `Install-AgentHub.ps1` (junctions; **não** commit junctions).
- Não copie o corpo da skill de volta para `AGENTS.md` / rules always-on.
- Templates slim: `templates/agents/`, `templates/rules/`, `templates/copilot/`, `templates/antigravity/`.

## Proibido (sempre-on)

- Guias NestJS/Angular completos em `AGENTS.md`, `.cursorrules`, `*.mdc` com `alwaysApply: true`
- Duplicar o mesmo guia em `.agents/rules/*.md`, `.kiro/steering/*.md`, `copilot-instructions.md`, `source/AGENTS.md`, etc.
- Criar skill nova **só** dentro de um repo (sem passar pelo hub)

## Checklist rápido (antes de commit de instruções)

- [ ] Mudança de guia de stack? → hub `skills/.../SKILL.md`
- [ ] Nota só deste repo? → `AGENTS.md` seção `## Local`
- [ ] Rule Cursor? → ponteiro curto (&lt; 1 KB) ou `globs` **sem** `alwaysApply` se for longo
- [ ] Rodou `Inventory-AgentFiles.ps1`? Flags &gt; ~2 KB em always-on = **regressão**

## Inventário

```powershell
cd D:\AGENTS\scripts
.\Inventory-AgentFiles.ps1
```

## MCPs habilitados

O install **não** joga mais todo `mcp/*.template.json` em todo repo. A lista vem de `catalog/projects.json` (`mcp.common` + `families.*.mcp` + `mcp.extra`).

- `codegraph` — binário nativo (`codegraph serve --mcp --path <repo>`), sem dependência de runtime. **Todas** as famílias.
- `context7` — `npx -y @upstash/context7-mcp`; rate limits maiores com chave de API. **Todas** as famílias.
- `filesystem` — `npx -y @modelcontextprotocol/server-filesystem` restringido ao repo + hub. **Todas** as famílias.
- `mongodb` — `node` + `mongodb-mcp-server@2` **global** (`npm i -g`), somente leitura. Só família **nestjs**. URI local padrão: `mongodb://root:password@127.0.0.1:27017/erpclass?authSource=admin` (igual ao Docker/dev). Override: `$env:MDB_MCP_CONNECTION_STRING` no install. **Não** usa `npx`/`cmd` no Windows (processos órfãos). URI só em `env`. Desative o MCP do plugin Cursor (skills ok) e não duplique `mongodb` em `~/.cursor/mcp.json`.
- `openapi` — `npx -y @ivotoby/openapi-mcp-server --tools dynamic`. Só NestJS **com Swagger no `main.ts`**. Spec em `/swagger/json` (ou o `jsonDocumentUrl` do projeto). Omitido no **Codex**. A API local precisa estar rodando. Não grava JWT no `mcp.json`.
- `playwright` — `npx -y @playwright/mcp --headless`. Família **angular** e projetos `*-www` / `*-ajuda`. Omitido no **Codex** (`mcp.skipIdes`) porque já interrompeu o startup.
- `coreui` — `npx -y @coreui/docs-mcp --framework bootstrap`. Família **angular**. O MCP oficial ainda não tem framework Angular dedicado; use Bootstrap para componentes/classes CoreUI e complemente com https://coreui.io/angular/docs/ para sintaxe Angular.

Não entram no hub: GitHub, Stripe, Figma, Pencil, Chrome DevTools.

Para usar sua chave Context7, coloque `CONTEXT7_API_KEY` em `D:\AGENTS\.env` (ou exporte no processo) e rode o install. Sem a chave o servidor ainda funciona, mas com limites públicos.

## IDEs por máquina

Allow/exclude **não** é um padrão único no git. Cada PC copia `.env.example` → `.env` e define `AGENTHUB_IDES` / `AGENTHUB_EXCLUDE_IDES`. Sem `.env`, o fallback é `catalog/projects.json`. Exclude apaga skills/MCP dessa IDE.

O install **só grava para IDEs realmente instaladas nesta máquina** (footprint em disco / PATH — ver `Get-PresentIdes`). Isso vale tanto para a auto-detecção quanto para uma lista explícita `-Ides` / `AGENTHUB_IDES`: uma IDE pedida mas ausente é ignorada com aviso. Assim, levar o hub para outra máquina nunca cria `.<ide>/skills` nem MCP de uma IDE que não existe lá. Para forçar mesmo assim, use `-AllowMissing` (ver Revisão 2026-09-18).

## Revisão 2026-08-08

### OK (always-on fino)

- `AGENTS.md` / `.cursorrules` / `GEMINI.md` nos repos do workspace: tipicamente **0,2–1,1 KB**
- Ponteiros `stack-pointer-*.mdc` e `decorator-placement.mdc`: **&lt; 1 KB**
- Templates slim no hub já existem (agents, rules, copilot, antigravity)

### Status pós-Install (2026-08-08)

Rodado: `Install-AgentHub.ps1 -WriteAgents -RemoveUnusedIdeFolders` → **21 projetos**.

- Removido: `erpclass-erp/.cursor/rules/.cursorrules.mdc` (16 KB always-on)
- Slim: Copilot + Antigravity em todos os repos afetados
- Ponteiro Delphi: `stack-pointer-delphi.mdc` (~0,4 KB, sem `alwaysApply: true`)
- Inventário: **OK — nenhum always-on > 2 KB**

Nova conversa no Cursor para deixar de carregar a rule gorda em cache da sessão antiga.

## Revisão 2026-08-12 — correção de caminhos nativos

Auditoria encontrou caminhos que não correspondiam ao formato nativo real de
algumas ferramentas. Corrigido em `Install-AgentHub.ps1`:

| Ferramenta | Antes (errado) | Depois (correto) | Fonte |
|---|---|---|---|
| Antigravity MCP | `.antigravity\mcp.json` | `.agents\mcp_config.json` | prototypr.io "Where does Antigravity look for MCP servers?" |
| Antigravity rules | `.antigravity\.antigravityrules` | `.agents\rules\stack-pointer.md` | prototypr.io "Where does Antigravity look for Rules and Workflows?" |
| Antigravity skills | `.antigravity\skills\*` | `.agents\skills\*` | codelabs.developers.google.com (agents.md/skills.md pipeline) |
| OpenCode MCP | `.opencode\opencode.json` com `{"mcp":{"servers":{...}}}` | `opencode.json` na raiz do repo com `{"mcp":{...}}` (mapa direto) | opencode.ai/docs/config, opencode.ai/docs/mcp-servers |
| Devin MCP | `.devin\mcp.json` | `.devin\mcp_config.json` | docs.devin.ai/cli/extensibility/mcp/configuration |
| Kiro | só `AGENTS.md` | `AGENTS.md` + `.kiro\steering\stack-pointer.md` (nativo, `inclusion: always`) | kiro.dev/docs/steering |

`~\.gemini\GEMINI.md` é um arquivo **global por usuário** (todo o Gemini
CLI/Antigravity), não um arquivo por projeto — por isso o script não cria
mais `.gemini\GEMINI.md` dentro de cada repo.

Rode `Install-AgentHub.ps1 -MigrateLegacyPaths -WriteAgents` uma vez em cada
máquina para remover os artefatos gerados pela versão antiga
(`.antigravity\mcp.json`, `.antigravity\.antigravityrules`, `.antigravity\skills`,
`.opencode\opencode.json`, `.devin\mcp.json`, `.codex\claude`, `.gemini\GEMINI.md`) antes de
gerar os novos caminhos.

## Revisão 2026-08-20 — Claude Code, Codex, Devin

O catálogo e o `Install-AgentHub.ps1` passam a tratar estas três ferramentas
com os caminhos nativos atuais:

| Ferramenta | Detecção | Skills | MCP |
|---|---|---|---|
| Claude Code | `~/.claude` ou comando `claude` | `.claude\skills` | `.mcp.json` (raiz; `mcpServers`) |
| Codex | `~/.codex` ou comando `codex` | `.codex\skills` | **global** `~/.codex/config.toml` (`[mcp_servers.*]`) — ver Revisão 2026-09-07 |
| Devin | `~/.devin`, `%APPDATA%\devin` ou comando `devin` | `.devin\skills` | `.devin\mcp_config.json` |

Não gravar CLAUDE.md extra: o Claude Code já lê `AGENTS.md`.

## Revisão 2026-08-21 — MCP por família

O install deixa de mesclar todo `mcp/*.template.json` em todos os repos.

| Família / match | MCPs |
|---|---|
| todas | `codegraph`, `context7`, `filesystem` |
| nestjs (`*-api`, `*-auth`, `*-sync`, `*-hook`) | + `mongodb` (read-only) e + `openapi` se o `main.ts` tiver Swagger (não no Codex) |
| angular (`*-admin`, `*-dash`, `*-app`, `*-cob`) e `*-www` / `*-ajuda` | + `playwright` (headless; **não** no Codex) |
| android (`mobiclass-apk`, `mobiclass-leitor`, `mobiclass-comanda`) | só o trio comum |
| delphi / minimal | só o trio comum |

Desative os plugins globais MongoDB e Playwright no Cursor se quiser evitar ferramentas duplicadas (plugin = todos os workspaces; hub = só a família certa).

## Revisão 2026-08-23 — code-review-graph → codegraph

O `code-review-graph` (MCP Python + skill + hooks Cursor `crg-*`) foi removido
da stack: catálogo, templates MCP, lógica de venv/build em
`Install-AgentHub.ps1`, `Fix-CursorHooks.ps1` e a skill dedicada.

Substituído pela ferramenta `codegraph` (github.com/colbymchenry/codegraph,
MIT, sem API key):

- Binário nativo instalado globalmente (`npm i -g @colbymchenry/codegraph`
  ou o instalador oficial) — sem venv/runtime dedicado no hub, diferente do
  code-review-graph.
- `mcp/codegraph.template.json`: `codegraph serve --mcp --path {{REPO}}`,
  `cwd = {{REPO}}`.
- `codegraph init <repo>` roda uma vez por projeto (cria `.codegraph/`,
  gitignored) via `Install-AgentHub.ps1`; o índice depois auto-sincroniza
  sozinho (file watcher do `codegraph serve`) — não precisa de hooks Cursor
  como o `crg-update.sh` antigo.
- Skill `codegraph` nova (nestjs/angular/android/minimal, mesmo padrão do
  code-review-graph antigo); ferramenta MCP principal é `codegraph_explore`
  (retorna código-fonte + call paths + blast radius em uma chamada).
- As skills de processo (`debug-issue`, `explore-codebase`, `refactor-safely`,
  `review-changes`) foram reescritas em torno de `codegraph_explore` — os
  nomes de ferramenta antigos do code-review-graph (`semantic_search_nodes_tool`,
  `get_minimal_context`, `detail_level`, etc.) não existem no codegraph e
  foram removidos.
- **Não** rodar `codegraph install`: sobrescreveria os `mcp.json` gerados
  pelo hub (mesmo motivo que já valia para `code-review-graph install`).

## Revisão 2026-08-24 — Android (claude-android-ninja)

Família `android` no catálogo para `mobiclass-apk`, `mobiclass-leitor` e
`mobiclass-comanda` (saíram de `excludeProjectNames`).

- Vendor: submodule `vendor/claude-android-ninja` (https://github.com/Drjacky/claude-android-ninja).
- Junction `skills/claude-android-ninja` → vendor (gitignored, recriada pelo install).
- Apps atuais são Java + XML Views; a skill é Kotlin/Compose — o `AGENTS.md` pede para **não** migrar a stack sem pedido explícito.
- Skills também em `.github/skills` (Copilot/VS Code) e `.codex/skills` (Codex).
- `mobiclass-apk` hoje só tem `.idea`; o install inclui o nome da família mesmo sem `src/` / `.git`.

## Revisão 2026-08-25 — MongoDB MCP sem npx

No Windows, `cmd /c npx mongodb-mcp-server` deixa cadeias `npx → cmd → conhost → node` órfãs quando o Cursor fecha (e reinícios acumulam dezenas de processos).

- Template e install passam a `node` + `mongodb-mcp-server@2` **global** (`dist/esm/index.js`).
- URI continua só em `env` (`MDB_MCP_CONNECTION_STRING`), não em `args`.
- O install aplica o mesmo payload a **todas** as IDEs do `Write-McpConfigs` (incluindo Antigravity em `.agents/mcp_config.json`).
- Plugin Cursor: MCP vazio, skills ok. Não duplicar `mongodb` em `~/.cursor/mcp.json`.

## Revisão 2026-09-07 — Codex MCP (codegraph)

O install detectava o Codex e copiava as skills pra `.codex/skills/`, mas **nunca
escrevia config de MCP** pro Codex — `Write-McpConfigs` não tinha braço `Codex`, e a
suposição antiga de `.codex/config.toml` por projeto estava errada: o Codex CLI (0.153)
lê MCP só do **global** `~/.codex/config.toml` (`[mcp_servers.*]`; `codex mcp add`
grava lá). Resultado: no Codex as skills `codegraph` / `explore-codebase` /
`debug-issue` / `refactor-safely` / `review-changes` carregavam mas `codegraph_explore`
não existia na sessão.

- Nova função `Ensure-CodexMcp` (roda uma vez por install, ao lado de `Ensure-AiMemory`):
  quando `Codex` está entre as IDEs detectadas, registra global via
  `codex mcp add <name> -- cmd /c …` (idempotente — `add` sobrescreve):
  - `codegraph` → `cmd /c codegraph serve --mcp` (**sem `--path`**: resolve o
    `.codegraph/` mais próximo pelo cwd, que o Codex aponta pro repo em que sobe).
  - `context7` → `cmd /c npx -y @upstash/context7-mcp` (+ `--api-key` se houver).
- `filesystem` / `mongodb` / `openapi` / `playwright` **não** vão pro Codex: presos a
  caminho/URL/conexão do projeto, não dá pra representar numa entrada global.
- Sem braço `Codex` em `Write-McpConfigs` — a config do Codex é global, não por repo.
- Fix manual avulso: `codex mcp add codegraph -- cmd /c codegraph serve --mcp`.

## Revisão 2026-09-18 — Delphi removido, review-changes, Kiro por cópia, filtro de IDE ausente

Quatro mudanças nesta rodada:

### 1. Stack Delphi descontinuado

Removidos a família `delphi` do `catalog/projects.json`, a skill vazia
`skills/delphi-erpclass/`, os templates `templates/agents/delphi.md`,
`templates/copilot/delphi.md`, `templates/rules/stack-pointer-delphi.mdc`, e as
menções em steering (`tech.md`, `structure.md`, `product.md`), `minimal.md` e
`antigravity/rules.md`. Também um resquício em `Get-ProjectFamily`
(array hardcoded `nestjs/angular/delphi/android`) que quebrava o install com
`The property 'match' cannot be found`. Projetos `*-erp` agora caem em
`minimal`. O path `stack-pointer-delphi.mdc` foi mantido de propósito na lista
de cleanup do `AgentHub.Common.ps1` para limpar pointers de instalações antigas.

### 2. code-review-and-quality fora de commonSkills; review-changes desambiguada

Havia 3 skills de review competindo pelo mesmo gatilho. Nenhuma foi apagada
(as duas do vendor são junctions, não editáveis). Solução: `code-review-and-quality`
saiu de `catalog.commonSkills` (o install poda os junctions dela em todos os
repos), e a `description` da `review-changes` (skill do hub) foi reescrita para
declarar-se a revisão rápida/risco default e apontar as outras duas por nome.

### 3. Kiro carrega skills por CÓPIA, não junction

**O Kiro não segue directory junctions em `.kiro/skills/`** — só lê pastas
reais (a doc dele só documenta *copiar* skills). Testado: uma skill de pasta
real aparece no kiro-cli; um junction idêntico não. Os demais agentes (Cursor,
Codex, Antigravity, OpenCode, Claude) seguem junction normalmente.

- `New-JunctionOrCopy` ganhou `-ForceCopy`: copia a pasta (com marker
  `.agenthub-managed`, reaproveitando o mecanismo de poda existente) e converte
  junctions pré-existentes em cópia.
- `Link-ProjectSkills` marca só o root do Kiro (`.kiro/skills`) como copy-only.
- `Sync-Codegraph.ps1` também copia o `codegraph` no `.kiro/skills`.

**Consequência de manutenção:** a cópia do Kiro **não se auto-atualiza**. Ao
editar uma skill no hub, é preciso **re-rodar o install** para propagar as
cópias do Kiro (os junctions das outras IDEs refletem na hora). Cópia também
ocupa mais espaço que junction.

### 4. IDE ausente é filtrada mesmo com -Ides explícito

Antes, uma lista explícita `-Ides` / `AGENTHUB_IDES` pulava a checagem de
presença e escrevia `.<ide>/skills` + MCP para IDEs que não existiam na
máquina — problema ao levar o hub para outro PC. Agora a detecção de presença
foi extraída para `Get-PresentIdes` e é aplicada **também** ao override: uma
IDE pedida mas não instalada é ignorada com aviso. Novo switch `-AllowMissing`
restaura o comportamento antigo (forçar a lista) quando desejado.

Rodado: `Install-AgentHub.ps1 -WriteAgents` → 38 projetos, EXIT 0. Também
corrigido um `UnboundLocalError` em `agenthub_config.py` que abortava o install
quando um `text_patch` era pedido para um `AGENTS.md` ainda inexistente
(cloudclass-*): agora escreve o arquivo do zero nesse caso.

## Revisão 2026-09-18b — rastreamento de estado consertado, Delphi de volta, reset e alvo avulso

Auditoria motivada por "por que tantos problemas a cada `Install`". A resposta foi
medida, não suposta: **o rastreador de estado estava quebrado e falhava em
silêncio**. Os avisos `Preserved manual ...` não eram edições suas — era o
instalador se enganando, e o efeito colateral é que ele havia **parado de
atualizar** os arquivos always-on dos 38 repos.

### 1. O bug que congelou 133 arquivos

`agenthub_config.atomic()` gravava com `write_text()` sem `newline=''`. O payload
que vem do PowerShell já tem CRLF, e o Python traduzia de novo: o disco recebia
**CR CR LF**. Na leitura, universal newlines devolvia `\n\n`, que nunca era igual
ao CRLF guardado no estado. Resultado medido: **0 de 133** arquivos de texto
batiam com o snapshot; 366 arquivos de estado contra apenas 31 backups (backup só
é escrito quando há escrita real — elas haviam cessado).

Corrigido nos dois lados (`atomic` e `read_previous` usam `newline=''`). Novo
`scripts/agenthub_repair_state.py` repara o legado: classifica cada arquivo em
`repairable` / `resync-only` / `manual-edit` / `already-in-sync` e só mexe no que
é provadamente conteúdo do hub — edição manual de verdade é preservada e
reportada. Dry-run por padrão; `--apply` para gravar.

### 2. A posse dos MCP era catraca de mão única

Se o valor em disco divergisse uma vez, a entrada era marcada "manual" **para
sempre**: o hub não conseguia mais atualizar nem podar. Medido: 132 de 228
configs com `owned = {}` enquanto o disco tinha os 4-5 servidores do hub (afetava
justo os 4 clientes que o `ai-memory` reescreve). Agora entradas já idênticas ao
payload pretendido são readotadas — não altera o disco, só devolve a capacidade
de gerenciar. Edição real do usuário continua preservada.

Mesmo impasse existia em dois outros lugares, ambos corrigidos: `recognized`
exigia um marcador no corpo do texto (o `decorator-placement.mdc` não tem
nenhum), e o branch TOML não tinha caminho de adoção.

### 3. Uma falha em um projeto derrubava os 38

O loop principal não tinha `try/catch`. Um `package.json` malformado abortava a
execução inteira, deixando metade da frota configurada e metade intocada — o
mecanismo de drift. Agora cada projeto é isolado, falhas são acumuladas e
listadas no fim com causa e caminho, e o exit code reflete.

### 4. O catálogo virou fonte de verdade

Famílias eram resolvidas por lista hardcoded no código (foi o que quebrou quando
o Delphi saiu). Agora `Get-CatalogFamilies` devolve as famílias **na ordem do
JSON** e o catch-all (`*`) vai sempre para o fim. Adicionar família é editar só o
catálogo.

O mapa IDE → pastas/MCP existia em 8 cópias divergentes. Agora há um único
`Get-IdeRegistry` (Skills / Mcp / Property / CopySkills), lido por install,
uninstall, os sync e os diagnósticos.

### 5. Idempotência

A cópia de skills do Kiro era refeita a cada execução (~40 skills × 38 repos) —
o maior custo de I/O e a causa de o install estourar timeout. `Test-CopyUpToDate`
compara por caminho relativo + tamanho + SHA256 e pula. Também corrigido um
**flip-flop**: `Write-AgentsFile` e `Update-MattPocockAgentSkillsBlock` disputavam
o `AGENTS.md` (um terminava com 2 CRLF, o outro normalizava para 1), reescrevendo
76 arquivos em toda execução, para sempre.

Execução repetida agora: **0 reescritas, 0 cópias, 0 avisos**.

### 6. Delphi de volta, com skills

Família `delphi` reinserida (`*-erp`), com a skill `delphi-erpclass` escrita a
partir do código real (~2.275 `.pas`, ~1.255 `.dfm`; estrutura de `source/`;
convenção de unit com namespace pontuado; `Global.pas`/`Funcoes.pas` como legado
a não expandir; a armadilha de encoding ANSI/UTF-8; e referência aos
`source/docs/*.txt` do próprio projeto em vez de duplicá-los).

Diferença importante em relação à configuração antiga: **não** foi recriado o
`disabledCommonSkills`/`disabledSkillsUntilSelected`, que deixava o projeto
praticamente sem skills. O `erpclass-erp` passou de 22 para 36 skills.

### 7. Reset e alvo avulso

- `Uninstall-AgentHub.ps1 -Full -PruneState` seguido de `Install-AgentHub.ps1
  -WriteAgents` é um reset limpo validado: remove junctions **e** as cópias do
  Kiro, MCP, pointers e os registros de estado órfãos, e o reinstall volta ao
  estado íntegro **sem nenhum aviso falso**. `AGENTS.md` sobrevive de propósito
  (carrega a seção `## Local`); use `-ForceAgents` para substituí-lo.
- `-ProjectPath <pasta>` instala/limpa em qualquer pasta do disco e **ignora
  `D:\SISTEMAS` por completo**. Se a pasta é um repo, configura ela; se só contém
  repos, configura os filhos. Sem o parâmetro, o comportamento normal (varrer os
  roots do catálogo) é preservado.
- `$env:AGENTHUB_SISTEMAS` sobrescreve o container padrão, para o hub não ficar
  preso a uma letra de drive.

### 8. Testes

`scripts/Run-Tests.ps1` é o comando único (pytest + os dois testes de integração
PowerShell), com exit code confiável. Dois defeitos de teste corrigidos: o
`Test-Ecc.ps1` imprimia "passed" deixando `$LASTEXITCODE=1` vazado de uma chamada
nativa, e três testes do stocktake quebravam quando o stdin do processo pai está
redirecionado (`stdin=subprocess.DEVNULL`).

O `Test-Integration.ps1` estava quebrado desde a remoção do Delphi — e ao voltar
a rodar **capturou uma regressão real** introduzida nesta rodada
(`OrderedDictionary` não tem `ContainsKey`), num caminho que o install não
exercita. Cobertura nova para registro de IDE, ordem de família, detecção de
projeto e idempotência da cópia.

## Revisão 2026-09-18c — procedência das skills vendor e colisão de nomes

Pergunta que originou a revisão: "todas as skills de vendor estão sendo
instaladas? existe uma lista que separe quais são de cada pacote? como a
sobreposição é tratada?" Responder exigiu escavar o catálogo e os três clones
vendor — o que já era a resposta: **não havia** uma lista por pacote.

### Números (para contexto)

De 82 skills disponíveis nos pacotes multi-skill, 30 entram: 15 de 37 do
`mattpocock/skills`, 8 de 25 do `addyosmani/agent-skills`, 7 de 14 do
`obra/superpowers`. Mais 3 vendors single-skill (`unlazy`, `browser-harness`,
`claude-android-ninja`). Efetivo por projeto: 38 (nestjs), 40 (angular),
36 (delphi/android/minimal).

### 1. Um key de catálogo por pacote upstream

Antes: `mattPocockSkills` e `superpowersSkills` tinham chave própria, mas a
seleção do Addy Osmani estava diluída em `commonSkills` junto com os vendors
standalone — o install precisava de um filtro `$standaloneVendorSkills` só para
não procurar `unlazy` dentro do repo do Addy e avisar "Vendor skill missing".

Agora `commonSkills` guarda só o que **não** vem de pacote multi-skill
(`unlazy`) e existe `addyosmaniSkills`. `Get-UniversalSkillLists` devolve as
quatro listas indexadas pela chave de catálogo, então a procedência de uma skill
é consulta, não arqueologia.

### 2. Uma função resolve a lista por projeto

`Get-ProjectSkillNames` substitui a expressão que `Install-AgentHub.ps1` e
`Test-AgentHub.ps1` montavam **em separado** — divergência garantida a cada
lista nova. De quebra, `disabledCommonSkills` agora filtra todas as listas
universais, não só `commonSkills`: antes da separação, "common" era só onde a
seleção do Addy Osmani por acaso morava, e o filtro cobria muito mais terreno
do que o nome sugere.

### 3. Nome disputado por dois pacotes aborta o install

`skills/<nome>` é namespace plano: se duas listas reivindicam o mesmo nome, os
mirrors rodam em ordem e o último **repontava a junction em silêncio** — os 36
repos ganhariam conteúdo de um pacote que ninguém escolheu.

- `Assert-NoSkillNameCollisions` roda antes de qualquer escrita, não precisa dos
  clones vendor (funciona em máquina nova e em `-DryRun`) e aborta nomeando a
  skill, as listas em conflito e qual venceria. Duplicata *dentro* de uma lista
  é inofensiva e ignorada.
- Segunda linha de defesa em `New-JunctionOrCopy`: repontar de `vendor/<A>` para
  `vendor/<B>` emite aviso, cobrindo o caso que o catálogo não vê (uma skill que
  mudou de pacote upstream).

Hoje existe **uma** colisão real entre os três pacotes — `test-driven-development`,
no addyosmani e no superpowers — e ela não está selecionada em nenhum. Que é
exatamente o tipo de coisa que deixa de ser verdade sem ninguém perceber.

### Desduplicação semântica continua sendo curadoria

O que impede TDD/debug/plano/spec duplicados não é código: é o que **ficou fora**
do catálogo (`test-driven-development` ×2, `diagnosing-bugs`,
`debugging-and-error-recovery`, `writing-plans`, `executing-plans`,
`implement-spec`, `requesting-code-review`, `using-superpowers`…). O README
documenta o porquê na seção do Superpowers. As sobreposições que coexistem de
propósito (`code-review` × `code-review-and-quality` × `review-changes` ×
`receiving-code-review`; `spec-driven-development` × `to-spec`) seguem
desambiguadas só pela `description` — nada verifica isso.

### Validação

Suíte verde (`Run-Tests.ps1`: 29 pytest + 2 integrações). Install real nos 36
projetos: **0 warning, 0 link alterado, 0 arquivo reescrito, 0 colisão** — a
reorganização produziu conjunto efetivo idêntico. Contagens por projeto
inalteradas (38/40/36). `Test-AgentHub.ps1`: 180 linhas, 0 skill faltando, 0
config inválida. `Inventory-AgentFiles.ps1`: 526 linhas, nada acima de 2 KB.
