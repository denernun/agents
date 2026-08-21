# Troubleshooting: Codex MCP Startup

## Erro atual

```
⚠️ MCP startup interrupted. The following servers were not initialized:
code-review-graph, codex_apps, context7, github, node_repl, playwright
```

## Análise

### MCPs que configuramos (devem funcionar):
1. ✅ **code-review-graph** - Python está OK, mas pode ter problema de permissões ou timeout
2. ✅ **context7** - Requer `npx` (Node.js)

### MCPs que NÃO configuramos (vêm de plugins):
3. ❌ **codex_apps** - Plugin do Codex que não configuramos
4. ❌ **github** - Plugin do Codex (precisa OAuth adicional)
5. ❌ **node_repl** - MCP interno do Codex (já configurado, mas pode ter problema)
6. ❌ **playwright** - Plugin desabilitado agora

## Soluções

### Solução 1: Desabilitar plugins que dependem de MCPs não configurados

Edite `~/.codex/config.toml` e desabilite os plugins problemáticos:

```toml
# Já fizemos isso para:
[plugins."playwright@claude-plugins-official"]
enabled = false

[plugins."claude-md-management@claude-plugins-official"]
enabled = false

[plugins."code-simplifier@claude-plugins-official"]
enabled = false
```

### Solução 2: Verificar se npx está disponível

```powershell
# Verificar Node.js/npx
node --version
npx --version

# Se não tiver, instalar Node.js:
# https://nodejs.org/
```

### Solução 3: Aumentar timeout dos MCPs (se necessário)

Adicione timeout maior no config:

```toml
[mcp_servers.code-review-graph]
command = 'D:\AGENTS\.venv-code-review-graph\Scripts\python.exe'
args = ["-m", "code_review_graph", "serve"]
cwd = 'D:\SISTEMAS\SHOPCLASS\shopclass-app'
type = "stdio"
startup_timeout_sec = 120  # ← adicionar esta linha
```

### Solução 4: GitHub OAuth

Para o plugin GitHub funcionar, além do token:

1. No Codex, digite: `/plugins`
2. Encontre "GitHub" → Clique em "Configure"
3. Faça login via OAuth no navegador
4. Autorize o Codex a acessar sua conta GitHub

### Solução 5: Ignorar MCPs opcionais (mais simples)

Os erros de MCP não impedem o Codex de funcionar. Você pode simplesmente ignorá-los e usar o Codex normalmente. Os MCPs que **realmente** precisamos são apenas:

- `code-review-graph` (análise de código)
- `context7` (busca docs) - opcional

Os outros são recursos adicionais que podem ser habilitados depois se necessário.

## Teste simples

Após desabilitar os plugins problemáticos:

1. Feche o Codex completamente
2. Reabra
3. Teste um comando simples: "Explain this codebase"

Se funcionar, os MCPs principais estão OK.

## Status atual

✅ TOML válido (sem erros de sintaxe)
✅ Paths corretos (Python, cwd)
✅ code-review-graph instalado e funcionando
⚠️ Alguns plugins tentando usar MCPs não configurados
⚠️ Node.js/npx pode não estar no PATH (para context7)

## Recomendação

**Opção A (conservadora)**: Desabilite todos os plugins que dão erro e use apenas os essenciais:
- ✅ code-review
- ✅ commit-commands
- ✅ feature-dev
- ✅ remember
- ✅ security-guidance

**Opção B (completa)**: Configure todos os MCPs opcionais:
1. Instalar Node.js para npx (context7)
2. Fazer OAuth do GitHub
3. Descobrir o que é `codex_apps` e configurar

**Sugestão**: Comece com Opção A e adicione recursos conforme necessário.
