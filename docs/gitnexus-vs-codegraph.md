# GitNexus vs codegraph — vale a troca?

**Data da análise:** 2026-09-04
**Veredito curto:** **não trocar.** Ficar com o `codegraph`. O GitNexus é um
projeto forte e tem recursos que o codegraph não tem, mas para o AgentHub ele
traz um bloqueio de licença (produtos comerciais) e atrito de integração que
não compensam o ganho.

---

## O que cada um é

| | **codegraph** (`@colbymchenry/codegraph`) — atual no hub | **GitNexus** (`abhigyanpatwari/GitNexus`) |
|---|---|---|
| Ideia | Grafo de conhecimento local, pré-indexado, para agentes (MCP) | "Zero-server code intelligence": grafo + Graph RAG + explorador visual no browser |
| Formato | 1 binário nativo autocontido (kernel Rust) | Monorepo Node/TypeScript (CLI + web + MCP + server) |
| Storage | SQLite + FTS5 (`.codegraph/codegraph.db`) | LadybugDB embutido (com vetores) |
| Índice | Incremental, file-watcher nativo do SO (inclui `ReadDirectoryChangesW` no Windows), ~2s | Incremental; tree-sitter nativo/WASM |
| Busca | FTS5 + call-graph | Híbrida: BM25 + semântica (transformers.js) + RRF; clustering Leiden |
| Superfície MCP | **1 tool** exposto (`codegraph_explore`) que já inclui source + call paths + blast radius; os narrow tools existem mas ficam ocultos | **17 tools** (`query`, `context`, `impact`, `trace`, `detect_changes`, `cypher`, `rename`, `route_map`, `tool_map`, `shape_check`, `api_impact`…) |
| Skills | nenhuma (o hub tem a skill `codegraph` que ensina a usar) | **11 skills** auto-deployadas em `.claude/skills/` e `.agents/skills/` no `gitnexus setup` |
| LLM / API key | Nenhuma. 100% local | Núcleo não precisa; **geração de wiki** usa OpenAI/compatível (opcional) |
| Linguagens | 20+ (TS/JS, Python, Go, Rust, Java, C#, PHP, Ruby, C/C++, Swift, Kotlin…), frameworks (NestJS, Express, Django…) | 14+ (TS/JS, Python, Java, Kotlin, Go, Rust, C#, PHP, Swift, C++, Dart, Zig…) |
| Extra | — | Explorador visual (Sigma.js) no browser; grupos multi-repo (mapas de serviço); `gitnexus wiki`; taint analysis / PDG |
| Licença | **MIT** | **PolyForm Noncommercial** (licença comercial paga via akonlabs.com) |
| Maturidade (2026-09-04) | ~69,6k ★ · criado jan/2026 · 964 commits · releases estáveis | ~47k ★ · criado ago/2025 · 1.921 commits · **RCs diários** (`v1.6.11-rc.48`) |
| Editores | Claude Code, Codex, Gemini, Cursor, OpenCode, Antigravity, Kiro, Copilot, Hermes | Claude Code, Cursor, Codex, Antigravity, OpenCode, CodeBuddy, Qoder, Windsurf |

---

## Por que **não** trocar

### 1. Licença — provável bloqueio
Os produtos do hub (ERPCLASS, NFECLASS, SHOPCLASS, MOBICLASS, CRMCLASS) são
**software comercial**. O GitNexus é **PolyForm Noncommercial**: uso comercial
exige comprar licença. O `codegraph` é MIT, sem essa preocupação. Só isso já
inverte o ônus da prova.

### 2. Atrito de integração com o hub
- O `gitnexus setup` **escreve as próprias 11 skills** em `.claude/skills/` e
  `.agents/skills/` — exatamente as pastas que o `Install-AgentHub.ps1`
  gerencia com junctions. Duas ferramentas mandando em `skills/` = conflito,
  ruído, e disputa com o prune do hub.
- É Node. O hub já documenta a dor de processo Node/npx órfão no Windows (toda
  a saga do `mongodb-mcp-server` virou "node + entry global, nunca npx"). Mais
  um MCP Node always-on por projeto piora isso.
- O codegraph já está wired: `.codegraph/` por projeto, `mcp.json` gerado pelo
  hub, `codegraph init` no `Install-AgentHub.ps1`. Trocar mexe em toda essa
  cadeia.

### 3. Superfície vs. filosofia do hub
O hub otimiza para **contexto enxuto** e **menos tool calls**. O design de
1-tool do codegraph (`codegraph_explore` resolve "como X funciona", "como X
chega em Y", "o que quebra se eu mudar Z" numa chamada) casa melhor com isso
que os 17 tools do GitNexus — mais poder, mais decisões pro agente, mais
chamadas encadeadas.

### 4. Churn
GitNexus solta release-candidate **todo dia**. Para uma ferramenta de
infraestrutura que roda em ~30 repos, estabilidade > features novas semanais.

---

## Onde o GitNexus ganha (e o que fazer com isso)

| Vantagem real do GitNexus | Vale puxar pro hub? |
|---|---|
| **Explorador visual** do grafo no browser (drop de repo/ZIP → grafo interativo) | Não pro hub, mas **ótimo ad-hoc**: dá pra usar a web UI (roda client-side, nada sobe pra nuvem) quando você quer *ver* a arquitetura de um repo. Sem instalar nada nos projetos. |
| **Grupos multi-repo** / mapas de serviço | Interessante — o hub tem famílias que conversam (`*-api` ↔ `*-admin`). Mas hoje não é dor suficiente. Reavaliar se "impacto cross-repo" virar necessidade recorrente. |
| `gitnexus wiki` (doc gerada por LLM) | Fora de escopo; e o hub evita depender de API key de LLM. |
| Busca semântica (embeddings) | O `codegraph_explore` com FTS5 + call graph tem sido suficiente. Não é gap sentido. |

---

## Recomendação

1. **Manter `codegraph`** como o grafo de conhecimento wired no hub.
2. **Não** rodar `gitnexus setup` nos repos dos produtos (licença + conflito de skills).
3. Se quiser explorar visualmente uma arquitetura, usar a **web UI do GitNexus**
   pontualmente (client-side, sem instalar nos projetos, sem tocar em `skills/`).
4. Revisar esta decisão se: (a) surgir necessidade recorrente de análise de
   impacto **cross-repo**, ou (b) o GitNexus mudar para uma licença permissiva.
