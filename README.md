# AgentHub

Fonte única de skills, templates e scripts para agentes de IA nos produtos **ERPCLASS**, **NFECLASS**, **SHOPCLASS**, **MOBICLASS** e **CRMCLASS**.

> ## AVISO — manter organizado
>
> - **Always-on fino** (`AGENTS.md`, `.cursorrules`, rules `.mdc` curtas): só ponteiros. Meta **&lt; ~2 KB**.
> - **Guia de stack gordo** vive **só** em `skills/` neste hub (carrega sob demanda).
> - **Nunca** recolocar NestJS/Angular/Delphi completo em `AGENTS.md`, `.cursorrules`, `alwaysApply: true`, Antigravity rules ou Copilot gordo.
> - Edite no hub → rode `Install-AgentHub.ps1` → commit hub + `AGENTS` enxutos nos repos.
> - Detalhes e última revisão: [`docs/CONTEXT-HYGIENE.md`](docs/CONTEXT-HYGIENE.md).
> - Se `Inventory-AgentFiles.ps1` listar always-on &gt; 2 KB → **regressão**; não ignore.

## Por quê

- `AGENTS.md` / rules always-on estavam duplicando o mesmo guia NestJS/Angular (~5–20 KB) em dezenas de repos e IDEs.
- Skills carregam **sob demanda**; AGENTS deve ficar **curto** (nome, stack, comandos, ponteiros).

---

## Setup rápido (máquina nova)

### Pré-requisitos

| Requisito | Por quê | Instalação |
|-----------|---------|------------|
| **Git** | Clone do hub + submodules | `winget install Git.Git` |
| **PowerShell 7+** | Scripts usam sintaxe PS7 | `winget install Microsoft.PowerShell` |
| **Node.js 18+** | MCPs (npx) + pacotes globais (`mongodb-mcp-server`, `codegraph`) | `winget install OpenJS.NodeJS.LTS` |
| **codegraph** | Grafo de conhecimento do código (MCP) | O `Install-AgentHub.ps1` faz `npm i -g @colbymchenry/codegraph` se faltar |
| **Docker** _(opcional)_ | MongoDB local | Já instalado se usa containers |

> **Sobre pacotes npm**: a maioria dos MCPs (`context7`, `filesystem`, `openapi`, `playwright`) usa `npx -y`. **MongoDB não**: no Windows o `npx` via `cmd` deixa processos órfãos. O install usa `node` + `mongodb-mcp-server@2` global (`npm i -g mongodb-mcp-server@2`).
>
> **Sobre codegraph**: binário nativo (Rust + wrapper Node). O install instala globalmente se faltar (`npm i -g @colbymchenry/codegraph`). O hub gera o `mcp.json` apontando pro binário; **não** rode `codegraph install` (ele sobrescreveria os `mcp.json` gerados pelo hub). Depois roda `codegraph init` uma vez por projeto (cria `.codegraph/`, local, gitignored).

### Clone e instalação

```powershell
# 1. Clone com submodules
git clone --recurse-submodules git@github.com:denernun/agents.git D:\AGENTS

# Se o clone já existia sem submodule:
git -C D:\AGENTS submodule update --init --recursive

# 2. Copie o .env desta máquina (IDEs diferem por PC; o ficheiro não vai no git)
copy D:\AGENTS\.env.example D:\AGENTS\.env
# Edite AGENTHUB_IDES e AGENTHUB_EXCLUDE_IDES

# 3. Opcional: chave para rate limits maiores no context7
#    (também pode ir no .env como CONTEXT7_API_KEY)

# 4. Rode o instalador
cd D:\AGENTS\scripts
.\Install-AgentHub.ps1 -WriteAgents -RemoveUnusedIdeFolders
```

O instalador faz tudo automaticamente:
- Detecta IDEs instaladas na máquina
- Baixa vendor skills (submodules `addyosmani/agent-skills` e `Drjacky/claude-android-ninja`)
- Cria junctions de skills em cada projeto
- Gera configs MCP por projeto e por IDE
- Roda `codegraph init` nos projetos que ainda não têm `.codegraph/`
- Escreve `AGENTS.md` enxuto (preserva seção `## Local`)
- Remove regras gordas duplicadas

---

## Migrar para outra máquina

O hub é **portátil** — basta clonar o repositório e rodar o install:

```powershell
# Na máquina nova:
git clone --recurse-submodules git@github.com:denernun/agents.git D:\AGENTS
cd D:\AGENTS\scripts
.\Install-AgentHub.ps1 -WriteAgents -RemoveUnusedIdeFolders
```

**O que NÃO precisa copiar manualmente:**
- Junctions em repos (`skills/`, `references`) — recriadas pelo install
- Configs MCP dos projetos — regeneradas pelo install
- Vendor skills — baixadas via git submodule (`vendor/addyosmani-agent-skills`, `vendor/claude-android-ninja`)

**O que precisa configurar na máquina nova:**
- Copiar `.env.example` → `.env` e ajustar `AGENTHUB_IDES` / `AGENTHUB_EXCLUDE_IDES` (cada PC tem IDEs diferentes)
- Opcionalmente `CONTEXT7_API_KEY` (no `.env` ou setx). Mongo local já vai no template (`root` / `password`).
- Ter os repos de produto em `D:\SISTEMAS\<ROOT>\` (o install detecta o que existir)
- IDEs instaladas (o install detecta e depois aplica allow/exclude do `.env`)

---

## IDEs suportadas

O install **detecta** o que está na máquina e depois aplica a política local:

1. `D:\AGENTS\.env` — `AGENTHUB_IDES` e `AGENTHUB_EXCLUDE_IDES` (por máquina, gitignored)
2. Sem `.env`, fallback: `catalog/projects.json` → `ides` / `excludeIdes`
3. `-Ides` na linha de comando ainda restringe a allowlist desta execução; o exclude continua a valer

Cópia inicial: `copy .env.example .env`

| IDE | Detecção | Skills em | MCP config em |
|-----|----------|-----------|---------------|
| **Cursor** | `~\.cursor` | `.cursor\skills\` | `.cursor\mcp.json` |
| **Kiro** | `~\.kiro` | `.kiro\skills\` | `.kiro\settings\mcp.json` |
| **OpenCode** | `opencode` no PATH | `.opencode\skills\` | `opencode.json` |
| **Antigravity** | `~\.gemini` | `.agents\skills\` | `.agents\mcp_config.json` |
| **VS Code** | `~\.vscode` | `.github\skills\` | `.vscode\mcp.json` |
| **Claude** | `~\.claude` | `.claude\skills\` | `.mcp.json` |
| **Codex** | `~\.codex` | `.codex\skills\` | `.codex\` |
| **Devin** | `~\.devin` | `.devin\skills\` | `.devin\mcp_config.json` |

Quem estiver em `AGENTHUB_EXCLUDE_IDES` (ou `excludeIdes` do catálogo) **não** recebe skills/MCP e o install **apaga** as configs do hub dessa IDE. O mapa está em `Get-IdeManagedPaths`.

`AGENTHUB_IDES=auto` (ou vazio) = todas as IDEs detectadas, menos o exclude.

### Forçar lista de IDEs

```powershell
# Ignorar detecção automática:
.\Install-AgentHub.ps1 -Ides Cursor,VSCode,Kiro -WriteAgents
```

### Remover IDEs que não uso

```powershell
# 1. Rode o install apenas com as IDEs desejadas:
.\Install-AgentHub.ps1 -Ides Cursor,Kiro -WriteAgents

# 2. Remova as pastas das IDEs não utilizadas:
.\Install-AgentHub.ps1 -RemoveUnusedIdeFolders
```

O `-RemoveUnusedIdeFolders` remove pastas configuradas em `catalog/projects.json` → `unusedIdeFolders` (hoje: `.qoder`, `.codebuddy`).

Para remoção completa de tudo que o hub gerou:

```powershell
# Apenas junctions (seguro, reversível):
.\Uninstall-AgentHub.ps1

# Tudo: junctions + MCPs + rules + pointers (cirúrgico: preserva MCPs manuais):
.\Uninstall-AgentHub.ps1 -Full

# Preview sem remover:
.\Uninstall-AgentHub.ps1 -Full -DryRun
```

---

## MCPs por família

Definidos em `catalog/projects.json`:

| Família | Projetos | MCPs |
|---------|----------|------|
| **Todos** | `*` | `codegraph`, `context7`, `filesystem` |
| **NestJS** | `*-api`, `*-auth`, `*-sync`, `*-hook`, `*-cob-api` | + `mongodb` (read-only), `openapi` (se Swagger detectado) |
| **Angular** | `*-admin`, `*-dash`, `*-app`, `*-cob` | + `playwright`, `coreui` |
| **Android** | `mobiclass-apk`, `mobiclass-leitor`, `mobiclass-comanda` | só os comuns |
| **Sites** | `*-www`, `*-ajuda` | + `playwright` |
| **Delphi** | `*-erp` | só os comuns |

### OpenAPI

- Detectado automaticamente se `src/main.ts` contém `SwaggerModule`
- A porta é lida de `src/config/.development.json` (campo `api.port`, `auth.port` ou `port`)
- **Requer a API rodando** para o MCP conectar (ele busca o spec em runtime)
- URL padrão: `https://localhost:<porta>/docs-json`

### MongoDB

- Padrão local (igual ao `.development.json` das APIs): `mongodb://root:password@127.0.0.1:27017/erpclass?authSource=admin`
- Override no install: `$env:MDB_MCP_CONNECTION_STRING`
- Modo read-only por padrão
- Launch: `node <npm-global>/mongodb-mcp-server/dist/esm/index.js` (URI só em `env`, não na linha de comando)
- **Não** ligue o MCP do plugin MongoDB do Cursor (skills do plugin ok). **Não** deixe `mongodb` também em `~/.cursor/mcp.json` — o hub já grava por projeto NestJS; duplicar abre outro processo em toda janela.

---

## Testando os MCPs

Após instalar e conectar, use estes prompts para validar:

### Teste MongoDB

> "Liste os databases disponíveis no MongoDB e mostre as collections do database principal"

ou

> "Consulte a collection `users` e mostre os 3 primeiros documentos"

### Teste OpenAPI

> "Liste todos os endpoints disponíveis na API usando o openapi MCP"

ou

> "Mostre os detalhes do endpoint POST /auth/login — quais parâmetros ele aceita?"

### Teste codegraph

> "Use codegraph_explore para explicar como o fluxo de autenticação funciona neste projeto"

### Teste context7

> "Busque a documentação do NestJS sobre Guards usando o context7"

### Teste CoreUI

> "Busque a documentação do CoreUI sobre cAlert — mostre props e eventos disponíveis"

> "Liste os componentes CoreUI disponíveis para Angular"

---

## Verificação e diagnóstico

### Inventário (verifica tamanho dos always-on)

```powershell
.\Inventory-AgentFiles.ps1
```

Qualquer arquivo always-on > 2 KB é uma regressão.

### Preview sem alterar nada

```powershell
.\Install-AgentHub.ps1 -DryRun
```

### Verificar configs MCP geradas

```powershell
# Ver o MCP de um projeto específico:
Get-Content "D:\SISTEMAS\ERPCLASS\erpclass-api\.kiro\settings\mcp.json" | ConvertFrom-Json | ConvertTo-Json -Depth 5
```

### Diagnosticar MCP com falha

1. **Verificar se o serviço base está rodando** (API para openapi, Docker para mongodb)
2. **MongoDB**: Docker no ar, user `root` / senha `password` (`authSource=admin`)
3. **Testar o server diretamente**:

```powershell
# MongoDB (binário global, sem npx):
node "$(npm root -g)/mongodb-mcp-server/dist/esm/index.js" --help

# OpenAPI:
cmd /c "npx -y @ivotoby/openapi-mcp-server --help"

# codegraph:
codegraph status "D:\SISTEMAS\ERPCLASS\erpclass-api" --json
```

4. **Reiniciar a IDE** após mudanças em variáveis de ambiente (setx)
5. **Re-rodar o install** se templates foram atualizados:

```powershell
.\Install-AgentHub.ps1 -WriteAgents
```

---

## Opções do Install

| Flag | Efeito |
|------|--------|
| `-DryRun` | Só mostra o que faria, não altera nada |
| `-Ides Cursor,VSCode,Kiro` | Força lista de IDEs (senão detecta automaticamente) |
| `-WriteAgents` | Reescreve `AGENTS.md` enxuto (preserva seção `## Local`) |
| `-RemoveUnusedIdeFolders` | Remove `.qoder`, `.codebuddy` e rules gordas duplicadas |
| `-HubPath` | Caminho do hub se o script não achar `skills/` ao lado |
| `-IncludeQoder` | Habilita Qoder (fora da lista padrão) |
| `-MigrateLegacyPaths` | Remove artefatos de versões antigas antes de regravar nos caminhos corretos |

---

## Estrutura do hub

```
D:\AGENTS/
  catalog/projects.json   # families, match patterns, MCPs, IDEs
  docs/                   # CONTEXT-HYGIENE, SKILLS-PLAYBOOK (quando usar cada skill),
                          #   gitnexus-vs-codegraph, unlazy-cheatsheet, superpowers/
  mcp/                    # templates MCP (*.template.json / *.template.toml)
  scripts/
    Install-AgentHub.ps1    # instala tudo
    Uninstall-AgentHub.ps1  # remove tudo (ou só junctions)
    Inventory-AgentFiles.ps1 # audita tamanhos
  skills/                 # guias on-demand por stack/processo
  templates/
    agents/               # AGENTS.md enxutos por família
    rules/                # ponteiros curtos p/ Cursor (.mdc)
    copilot/              # instruções GitHub Copilot por família
    antigravity/          # pointer Antigravity
  vendor/                 # submodules: addyosmani/agent-skills, mattpocock/skills,
                          #   obra/superpowers, Drjacky/claude-android-ninja, unlazy, browser-harness
```

---

## Qual skill usar em cada momento

Ver [`docs/SKILLS-PLAYBOOK.md`](docs/SKILLS-PLAYBOOK.md) — fluxo por fase
(ideia → spec → antes do código → implementação → debug → review → fechamento),
detalhe de cada skill (quando/como invocar), e fluxos prontos pra colar no chat.

---

## Manutenção do dia-a-dia

1. Edite a skill **no hub** (`skills/.../SKILL.md`)
2. Rode `Install-AgentHub.ps1` nas máquinas (junctions locais não vão no Git)
3. Commit do hub + `AGENTS.md` enxutos em cada repo

### Atualizar vendor skills

```powershell
git -C D:\AGENTS submodule update --remote
```

### Skills de processo (Superpowers)

[`obra/superpowers`](https://github.com/obra/superpowers) — metodologia de
desenvolvimento. **Só um subconjunto** entra no hub: as skills que **não**
colidem com o roteador base (`using-agent-skills`, do addyosmani) nem com as
skills do Matt Pocock. Lista em `catalog/projects.json` → `superpowersSkills`:

| Skill | Por que entra |
|---|---|
| `systematic-debugging` | disciplina de root-cause (camada acima do `debug-issue`/codegraph) |
| `receiving-code-review` | como reagir a feedback de review com rigor — ângulo que as outras não cobrem |
| `verification-before-completion` | "evidência antes de dizer que terminou" |
| `dispatching-parallel-agents` | orquestrar subagents paralelos |
| `using-git-worktrees` | isolamento por worktree |
| `finishing-a-development-branch` | decisão de como integrar a branch |
| `writing-skills` | TDD aplicado a skills (útil pra manter o próprio hub) |

**Ficaram de fora** (redundantes com o que já está ativo):
`using-superpowers` (roteador — conflita com `using-agent-skills`),
`brainstorming` (usa-se `grilling`/`grill-me` do Matt Pocock),
`test-driven-development` (usa-se `tdd` do Matt Pocock, mais enxuto),
`writing-plans`/`executing-plans`/`subagent-driven-development`
(usa-se `to-spec`/`to-tickets`/`implement` do Matt Pocock),
`requesting-code-review` (usa-se `code-review-and-quality` + `code-review`).

> Regra (ver `vendor/addyosmani-agent-skills/docs/comparison.md`): **um só
> roteador de metodologia ativo**. Skills individuais podem ser combinadas à
> la carte; dois meta-roteadores brigam por `/tdd`, roteamento e filosofia.

O install baixa o submodule `vendor/superpowers` e cria junctions
`skills/<nome>` → `vendor/superpowers/skills/<nome>` (gitignored, recriadas a
cada `Install-AgentHub.ps1`). O hook/plugin oficial do Superpowers **não** é
usado — só os `SKILL.md`, carregados sob demanda.

> **Trocar a lista depois:** editar `superpowersSkills` (ou `mattPocockSkills`,
> ou as `skills` de uma família) e rodar `Install-AgentHub.ps1` de novo. O
> install cria as junctions novas **e remove** as que saíram do catálogo
> (prune, igual ao que já fazia com MCP). Skills feitas à mão na pasta do
> projeto (pasta real, ou junction apontando para fora de `D:\AGENTS\skills`)
> não são tocadas.

---

## Troubleshooting

### MCP "Connection Failed" no Kiro/Cursor

| MCP | Causa comum | Solução |
|-----|-------------|---------|
| **openapi** | API não está rodando | Inicie a API (`npm run start:dev`) e clique Retry |
| **mongodb** | Docker parado, user/senha errados, ou `npx`/plugin a criar zumbis | Suba o Mongo local (`root` / `password`); o hub **não** usa npx. Desative o MCP do plugin Cursor e o `mongodb` global em `~/.cursor/mcp.json`. |
| **codegraph** | Binário não está no PATH, ou `.codegraph/` corrompido/travado | `npm i -g @colbymchenry/codegraph`; `codegraph unlock <repo>` se o índice ficou travado |
| **context7** | Rede instável ou rate limit | Defina `CONTEXT7_API_KEY` para mais requests |

### MCP global vs projeto

MCPs **universais** (como `ai-memory`, ver abaixo) ficam na config global do usuário.
MCPs **per-project** (`codegraph`, `context7`, `filesystem`, `openapi`, `mongodb`, `playwright`) ficam na config do projeto e são gerados pelo install.

Se um MCP aparecer com erro na config global mas funcionar por projeto, **remova-o da config global** — a de projeto tem prioridade.

---

## Memória compartilhada (ai-memory)

[`akitaonrails/ai-memory`](https://github.com/akitaonrails/ai-memory) — memória de longo prazo
**compartilhada entre agentes** (Claude Code, Cursor, OpenCode, Codex…): sai do Claude
no meio de uma task, abre o Codex no mesmo diretório e continua sem re-explicar a
arquitetura. Um binário Rust roda um servidor MCP/HTTP + hooks de ciclo de vida; a
wiki é markdown versionado por git. Funciona sem API key (modo zero-LLM).

### Diferença do resto do hub

| | `ai-memory` | `codegraph`, `mongodb`… |
|---|---|---|
| Config MCP | **1 entrada HTTP global** por agente (`~/.claude.json`, config do Cursor, plugin do OpenCode) | `mcp.json` por projeto |
| Hooks | globais (`~/.claude/settings.json`) — o hub **não** gerencia isso sozinho | — |
| Projeto atual | derivado do **git root / CWD** (opcional: `.ai-memory.toml`) | caminho passado como arg |
| Pré-requisito | **servidor rodando** + CLI `ai-memory` no PATH | binário no PATH |

Por isso o hub **não** escreve `ai-memory` nos `mcp.json` dos projetos: ele chama o
instalador nativo (`ai-memory install-mcp` / `install-hooks`), uma vez por agente
detectado, quando `AI_MEMORY_ENABLED=1` no `.env`.

### Setup

```powershell
# 1. Servidor (Windows: Docker Desktop; loopback-only, sem auth)
docker run -d --name ai-memory --restart unless-stopped `
  -p 127.0.0.1:49374:49374 -v ai-memory-data:/data `
  akitaonrails/ai-memory:latest

# 2. CLI `ai-memory` no PATH (ver docs/install.md do projeto — AUR, binário ou
#    `docker run --rm akitaonrails/ai-memory:latest ...` como wrapper)

# 3. .env do hub
#    AI_MEMORY_ENABLED=1
#    AI_MEMORY_URL=http://127.0.0.1:49374
#    AI_MEMORY_TOKEN=            (vazio no modo loopback)

# 4. Rode o install normalmente
.\Install-AgentHub.ps1 -WriteAgents
#    -SkipAiMemory        desliga o passo pontualmente
#    -WriteAiMemoryToml   grava .ai-memory.toml (project = "<repo>") por repo
#                         — só necessário em checkout ambíguo / monorepo
```

Mapeamento IDE detectada → agente: `Cursor→cursor`, `Claude→claude-code`,
`OpenCode→opencode`, `Codex→codex`, `Devin→devin`.

### Desinstalar

`.\Uninstall-AgentHub.ps1 -Full` roda `ai-memory uninstall --apply` (global, **todos os
agentes da máquina**) e remove o `.ai-memory.toml` gerado pelo hub.
