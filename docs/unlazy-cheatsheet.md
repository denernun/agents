# unlazy — folha de referência

Disciplina de conclusão: escreve os critérios verificáveis antes, executa os
checks, re-verifica o trabalho e só reporta "pronto" com evidência real.

## Quando usar

- ✅ Refactor multi-arquivo, migration, "auditar módulo X", trabalho longo ou paralelo
- ❌ Fix de 1 linha, resposta factual, ajuste trivial → **não** cria gates

## Como pedir (no chat do Cursor / Claude)

```
usa unlazy: <escopo em 1 frase> — garanta <resultados que têm que ser verdade>
usa unlazy tree 3: <escopo grande, dividido em folhas>
```

O agente escreve o `GATES.md`, implementa, roda os checks, re-verifica e audita
o relatório final contra o ledger.

## Comandos (rodar na raiz do projeto)

`DIR` = `.cursor/skills/unlazy/scripts` (Cursor) · `.claude/skills/unlazy/scripts` (Claude)

| Ação | Comando |
|---|---|
| Ver estado do ledger (não executa nada) | `node DIR/gate-check.mjs --status GATES.md` |
| Validar sintaxe do ledger | `node DIR/gate-lint.mjs GATES.md` |
| Aprovar os comandos e rodar | `node DIR/gate-check.mjs --approve GATES.md` |
| Rodar só os gates `[ ]` (já aprovados) | `node DIR/gate-check.mjs GATES.md` |
| **Re-verificar tudo** (mesmo os `[x]`) | `node DIR/gate-check.mjs --reverify GATES.md` |
| Ledger de saúde permanente | `node DIR/gate-check.mjs --reverify GATES.health.md` |

Exit codes: `0` tudo ok · `1` gate não cumprido · `2` erro de sintaxe/uso · `3` conflito de lease

## Ciclo de vida do `GATES.md`

1. Nasce com o pedido — 1 outcome observável por gate (`CHECK:` + `EXPECT:`).
2. Trabalho feito → gates `[x]` com `EVIDENCE:` (exit + hash real da saída).
3. **Pós-merge:** ledger de tarefa é descartável → `git rm GATES.md` (ou move o
   achado pra `docs/audits/` se tiver valor duradouro).
4. Gate impossível: não apaga → `ABANDON: G<n> <motivo>` (vira handoff no relatório).

## Convenções (definidas em 2026-09)

- **`GATES.md`** = tarefa efêmera (some no merge). **`GATES.health.md`** = check
  permanente de test/lint/build.
- **`.unlazy/`** fica **gitignored** em todos os repos (não commitar).
- Achado de auditoria com valor → `docs/audits/<data>-<nome>.md`, depois apaga o `.unlazy/`.
- **Não** substitui o vitest — o `CHECK:` do gate chama `npm test`. unlazy só
  prova que rodou e que o resultado bateu.
- Cursor não tem o "Stop hook" automático (é exclusivo do Claude Code) — a
  disciplina é pedir `usa unlazy` por tarefa.

## Task vs Health — como distinguir um `GATES.md`

| Sinal | 🩺 Saúde | 🎯 Tarefa |
|---|---|---|
| `Scope:` | "verificar que o projeto passa em X" | nomeia feature/fase |
| `OWNS:` | só `GATES.md` | lista código (`src/**`, `scripts/*.mjs`) |
| `CHECK:` | `npm run test/lint/build` genérico | script da feature, asserção de conteúdo |
| ciclo de vida | re-rodado igual ao longo do tempo | acaba no merge |
