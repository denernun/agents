# Status do Codex no AgentHub

Codex faz parte da lista `ides` em `catalog/projects.json`. O install detecta
`~/.codex` ou o comando `codex`.

## O que o script grava (por projeto)

### Skills

Junctions em `.codex/skills/<nome>` → `D:\AGENTS\skills\<nome>`.

O Codex também lê `.agents/skills` se o Antigravity estiver na lista detectada.
Não usamos mais `.codex/claude/` (caminho antigo; `-MigrateLegacyPaths` remove).

### MCP

Arquivo **do repo**: `.codex/config.toml` (projeto trusted).

O hub **não** escreve `~/.codex/config.toml`. Um `cwd` global do
`code-review-graph` apontaria para um único repo e quebraria os outros.

```toml
# AgentHub-managed MCP servers (rewritten by Install-AgentHub.ps1).
[mcp_servers.code-review-graph]
command = "D:/AGENTS/.venv-code-review-graph/Scripts/python.exe"
args = ["-m", "code_review_graph", "serve"]
cwd = "D:/SISTEMAS/ERPCLASS/erpclass-auth"

[mcp_servers.context7]
command = "cmd"
args = ["/c", "npx", "-y", "@upstash/context7-mcp"]

[mcp_servers.filesystem]
command = "cmd"
args = ["/c", "npx", "-y", "@modelcontextprotocol/server-filesystem", "D:/SISTEMAS/ERPCLASS/erpclass-auth", "D:/AGENTS"]
```

Em APIs NestJS o bloco gerenciado também inclui `[mcp_servers.mongodb]`
(read-only). Playwright e OpenAPI **não** são gravados no Codex — npx extra
já quebrou o startup (`mcp.skipIdes` no catálogo).

Plugins do Codex (github, playwright, …) continuam só no `~/.codex/config.toml`
do usuário — o hub não os gerencia. Mantenha o plugin Playwright desabilitado
lá, senão ele volta a competir com o trio estável.

## Comandos

```powershell
cd D:\AGENTS\scripts
.\Install-AgentHub.ps1 -Ides Codex -DryRun
.\Install-AgentHub.ps1 -WriteAgents -RemoveUnusedIdeFolders
```

## Verificar

```powershell
Get-ChildItem "D:\SISTEMAS\ERPCLASS\erpclass-auth\.codex\skills"
Get-Content "D:\SISTEMAS\ERPCLASS\erpclass-auth\.codex\config.toml"
```

Se o MCP não subir: o projeto precisa estar **trusted** no Codex. Settings
manuais (modelo, sandbox) ficam em `~/.codex/config.toml` e não são apagadas.

**Última atualização:** 2026-08-20
