# Design: Agent Hub

**Date:** 2026-08-07
**Status:** Approved — implementing
**Scope:** ERPCLASS, NFECLASS, MOBICLASS

## Goals

1. Stop shipping duplicate NestJS/Angular/Delphi guides in every `AGENTS.md` / Cursor rule / IDE folder.
2. One editable source (`D:\agents`) with per-machine junctions.
3. MCP only for IDEs the developer actually uses; remove unknown/unused IDE clutter (`.qoder`).
4. Keep always-on context tiny; load stack guides via skills on demand.

## Architecture

- **Hub** holds `skills/`, `templates/`, `mcp/`, `scripts/`, `catalog/`.
- **Install-AgentHub.ps1** detects IDEs under `%USERPROFILE%`, then per repo:
  - junctions of relevant skills into `.cursor/skills`, `.agents/skills` (Antigravity/OpenCode), etc.
  - MCP JSON for Cursor / VS Code / Kiro / Devin / OpenCode / Antigravity
  - slim `AGENTS.md` from family template
  - optional removal of `.qoder`, `.codebuddy`, fat `nestjs-rules.mdc` / `cursor.mdc`

## Families

| Family | Name patterns | Skills |
|--------|---------------|--------|
| nestjs | `*-api`, `*-auth`, `*-sync`, `*-hook` | nestjs-clean-architecture, code-review-graph, process skills |
| angular | `*-admin`, `*-dash`, `*-app` | angular-coreui, coreui-styling, code-review-graph, process |
| delphi | `*-erp` | delphi-erpclass, process |
| minimal | fallback | code-review-graph, process |

## Non-goals (this iteration)

- Disabling Cursor marketplace MCP plugins (Stripe, CockroachDB, …) — manual in Cursor Settings.
- Committing junctions into Git.
- Rewriting application source code.

## Follow-up (context hygiene — 2026-08-08)

Slimmed always-on duplicates:

- Delphi Cursor rule → `templates/rules/stack-pointer-delphi.mdc` (`alwaysApply: false`)
- Copilot → `templates/copilot/{nestjs,angular,delphi,minimal}.md`
- Antigravity → `templates/antigravity/rules.md`
- Fat `.cursorrules.mdc` removed by `Install-AgentHub.ps1`

See `docs/CONTEXT-HYGIENE.md`.

## Follow-up (MCP by family — 2026-08-21)

Install no longer merges every `mcp/*.template.json` into every repo.

- Common: `code-review-graph`, `context7`, `filesystem`
- NestJS APIs: + `mongodb` (read-only) and + `openapi` when Swagger exists in `main.ts` (skipped on Codex)
- Angular + `*-www` / `*-ajuda`: + `playwright` (skipped on Codex)
- Catalog fields: `mcp.common`, `mcp.skipIdes`, `mcp.extra`, `families.*.mcp`
