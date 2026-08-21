# AgentHub

Fonte única de skills, templates e scripts para agentes de IA nos produtos **ERPCLASS**, **NFECLASS**, **SHOPCLASS** e **MOBICLASS**.

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

## Setup (cada máquina / cada dev)

```powershell
git clone --recurse-submodules git@github.com:denernun/agents.git D:\AGENTS
# se o clone já existia sem submodule:
git -C D:\AGENTS submodule update --init --recursive

cd D:\AGENTS\scripts
# Opcional: exporte sua chave para rate limits maiores no context7
$env:CONTEXT7_API_KEY='sua-chave'
.\Install-AgentHub.ps1 -WriteAgents -RemoveUnusedIdeFolders
```

O venv do `code-review-graph` e as junctions das skills do Addy **não** vão no Git. O install recria os dois.

Skills do pack [addyosmani/agent-skills](https://github.com/addyosmani/agent-skills) ficam em `vendor/addyosmani-agent-skills` (submodule). Atualizar: `git -C D:\AGENTS\vendor\addyosmani-agent-skills pull`.

Opções úteis:

| Flag | Efeito |
|------|--------|
| `-DryRun` | Só mostra o que faria |
| `-Ides Cursor,VSCode,Kiro` | Força lista de IDEs (senão detecta por `~\.<ide>` / comando) |
| `-WriteAgents` | Reescreve `AGENTS.md` enxuto (preserva seção `## Local`) |
| `-RemoveUnusedIdeFolders` | Remove `.qoder`, `.codebuddy` e rules gordas duplicadas |
| `-HubPath` | Caminho do hub se o script não achar `skills/` ao lado |
| `-IncludeQoder` | Habilita Qoder (fora da lista padrão; veja `catalog/projects.json`) |
| `-MigrateLegacyPaths` | Remove artefatos de versões antigas (`.antigravity\mcp.json`, `.opencode\opencode.json`, `.devin\mcp.json`, `.codex\claude`, `.gemini\GEMINI.md`) antes de regravar nos caminhos corretos |

Agentes habilitados vivem em `catalog/projects.json` (`ides`). Hoje: **Cursor**, **VS Code**, **Kiro**, **OpenCode**, **Antigravity**, **Claude Code**, **Codex** e **Devin**. **Qoder** continua opt-in.

MCPs instalados por projeto: `code-review-graph`, `context7` e `filesystem`.

Se alguma IDE não aparecer na detecção automática:

```powershell
.\Install-AgentHub.ps1 -Ides Cursor,VSCode,Kiro,OpenCode,Antigravity,Claude,Codex,Devin -WriteAgents
```

## Estrutura

```
D:\AGENTS/
  skills/           # nestjs, angular, delphi, code-review-graph, processo
  templates/agents/ # AGENTS.md enxutos por família
  templates/rules/  # ponteiros curtos p/ Cursor
  mcp/              # templates code-review-graph, context7, filesystem
  catalog/          # families + match patterns + ides
  scripts/          # Install / Uninstall / Inventory / Fix-CursorHooks
  docs/             # CONTEXT-HYGIENE, superpowers, CODEX-STATUS
```

## Manutenção

1. Edite a skill **no hub** (`skills/.../SKILL.md`).
2. Rode `Install-AgentHub.ps1` nas máquinas (junctions locais não vão no Git).
3. Commit do hub + `AGENTS.md` enxutos em cada repo.

## Inventário

```powershell
.\Inventory-AgentFiles.ps1
```

## Troubleshooting

### Múltiplas janelas de terminal no Cursor (Windows)

Se ao usar o Cursor muitas janelas do Git Bash aparecerem executando `crg-update.sh`, é porque o code-review-graph criou hooks em shell script que não funcionam bem no Windows.

**Solução**: converter os hooks para PowerShell:

```powershell
cd D:\AGENTS\scripts
.\Fix-CursorHooks.ps1
```

Depois, reinicie o Cursor. Os hooks agora executam silenciosamente em PowerShell.

> **Nota**: `Install-AgentHub.ps1` agora faz essa conversão automaticamente, mas se você já tinha os hooks `.sh` antes, rode `Fix-CursorHooks.ps1` uma vez.

### Codex não inicializa MCPs (code-review-graph, context7)

O Codex lê MCP **por projeto** em `.codex/config.toml` (só se o projeto estiver trusted). Não usamos `~/.codex/config.toml` para o grafo — o `cwd` precisa ser o repo aberto.

1. Verifique se `Install-AgentHub.ps1` detectou o Codex (deve aparecer na lista de IDEs)
2. Rode `.\Install-AgentHub.ps1 -Ides Codex -WriteAgents` para forçar
3. Verifique `<repo>\.codex\config.toml` — deve ter `[mcp_servers.code-review-graph]`, `[mcp_servers.context7]` e `[mcp_servers.filesystem]`
4. Skills ficam em `<repo>\.codex\skills\` (junctions para o hub)
5. Reinicie o Codex após mudanças no config

**Plugins opcionais do Codex** (github, stripe, playwright) requerem configuração adicional — não gerenciados por este hub.

### Claude Code / Devin

| Ferramenta | Skills | MCP |
|------------|--------|-----|
| Claude Code | `.claude/skills/` | `.mcp.json` na raiz |
| Devin | `.devin/skills/` | `.devin/mcp_config.json` |
