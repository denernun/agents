# Higiene de contexto (agentes)

> ## AVISO — manter organizado
>
> Contexto **always-on gordo** = tokens desperdiçados em **toda** conversa.
> Guias NestJS / Angular / Delphi completos vivem **somente** em `skills/` (on-demand).
> **Nunca** recolocar esses guias em `AGENTS.md`, `.cursorrules`, rules com `alwaysApply: true`,
> `.agents/rules/*.md`, `.kiro/steering/*.md` ou `copilot-instructions.md`.
> Edite no hub → `Install-AgentHub.ps1` → commit só o que for texto versionado (AGENTS enxutos).

## O que entra no contexto (e quando)

| Camada | Arquivos típicos | Quando carrega | Tamanho alvo |
|--------|------------------|----------------|--------------|
| **Always-on** | `AGENTS.md`, `.cursorrules`, ponteiros `.mdc`, Copilot slim, `.agents/rules/stack-pointer.md` (Antigravity), `.kiro/steering/stack-pointer.md` (Kiro) | Toda conversa no repo | **&lt; 2 KB** cada |
| **On-demand** | Skills em `.cursor/skills/*`, `.agents/skills/*`, `.kiro/skills/*`, `.opencode/skills/*`, `.claude/skills/*`, `.codex/skills/*`, `.devin/skills/*` (junction → hub) | Só quando o agente abre a skill | OK 1–25 KB |
| **MCP** | `.cursor/mcp.json`, `.vscode/mcp.json`, `.kiro/settings/mcp.json`, `opencode.json` (raiz), `.agents/mcp_config.json`, `.mcp.json` (Claude Code), `.codex/config.toml`, `.devin/mcp_config.json` | Ferramentas MCP, não texto de guia | code-review-graph, context7, filesystem |
| **Local only** | seção `## Local` do `AGENTS.md` | Always-on, mas só notas do repo | Curto |

## Skills no hub (on-demand — ok serem maiores)

| Skill | ~KB | Família |
|-------|-----|---------|
| `nestjs-clean-architecture` | 21 | NestJS |
| `delphi-erpclass` | 16 | Delphi |
| `angular-coreui` | 10 | Angular |
| `coreui-styling` | 6 | Angular |
| `code-review-graph` | 2 | todas |
| `debug-issue` / `explore-codebase` / `refactor-safely` / `review-changes` | ~1 | processo |

## Fonte canônica

- Edite skills **somente** em `D:\AGENTS\skills/`.
- Replique com `Install-AgentHub.ps1` (junctions; **não** commit junctions).
- Não copie o corpo da skill de volta para `AGENTS.md` / rules always-on.
- Templates slim: `templates/agents/`, `templates/rules/`, `templates/copilot/`, `templates/antigravity/`.

## Proibido (sempre-on)

- Guias NestJS/Angular/Delphi completos em `AGENTS.md`, `.cursorrules`, `*.mdc` com `alwaysApply: true`
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

- `code-review-graph` — Python (`python -m code_review_graph serve`) para análise de grafo do repo.
- `context7` — `npx -y @upstash/context7-mcp`; rate limits maiores com chave de API.
- `filesystem` — `npx -y @modelcontextprotocol/server-filesystem` restringido ao repo + hub.

Para usar sua chave Context7, exporte antes de rodar o install:

```powershell
$env:CONTEXT7_API_KEY='sua-chave'
.\Install-AgentHub.ps1 -WriteAgents
```

Sem a chave o servidor ainda funciona, mas com limites públicos.

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
| Codex | `~/.codex` ou comando `codex` | `.codex\skills` | `.codex\config.toml` **por projeto** (não `~/.codex/config.toml`) |
| Devin | `~/.devin`, `%APPDATA%\devin` ou comando `devin` | `.devin\skills` | `.devin\mcp_config.json` |

Não gravar CLAUDE.md extra: o Claude Code já lê `AGENTS.md`. O Codex só aplica
`.codex/config.toml` em projetos **trusted**.

