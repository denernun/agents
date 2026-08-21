---
inclusion: always
---

# Tech Stack

## This repo (the hub itself)

- **Language**: PowerShell (scripts), Markdown (skills/templates/docs), JSON (catalog/MCP templates).
- No package.json / build system — this is not a compiled or bundled project.
- Windows-only tooling: junctions via `New-Item`/`mklink /J`, paths assume `D:\IA\agents` (hub) and `D:\SISTEMAS\<ROOT>` (product repos).

## Stacks the hub serves (documented in skills, not built here)

| Family | Stack | Matched project patterns |
|---|---|---|
| nestjs | NestJS + TypeScript, Clean Architecture, DDD | `*-api`, `*-auth`, `*-sync`, `*-hook`, `*-cob-api` |
| angular | Angular 22+, CoreUI, Clean Architecture | `*-admin`, `*-dash`, `*-app`, `*-cob` |
| delphi | Delphi VCL (ERPClass Domain/Providers, ANSI encoding) | `*-erp` |
| minimal | fallback, no specific stack | `*` |

Full stack conventions live in `skills/<family>/SKILL.md` — do not duplicate
them into always-on files (see Structure below). Refer users there for
stack-specific coding rules.

## MCP servers (templated in `mcp/*.template.json`)

- **code-review-graph** — Python (`python -m code_review_graph serve`), knowledge-graph-based code exploration/review. Preferred over Grep/Glob/Read for exploring target repos (see `skills/code-review-graph/SKILL.md`).
- **context7** — `npx -y @upstash/context7-mcp`, docs lookup. Optional `CONTEXT7_API_KEY` env var for higher rate limits.
- **filesystem** — `npx -y @modelcontextprotocol/server-filesystem`, scoped to the target repo + hub.

## Supported IDEs/agents

Cursor, VS Code, Kiro, OpenCode, Antigravity, Claude Code, Codex, Devin (Qoder is opt-in via
`-IncludeQoder`, disabled by default in `catalog/projects.json`).

## Common commands

Run from `D:\IA\agents\scripts` (PowerShell):

```powershell
# Full install: detect IDEs, link skills, write slim AGENTS.md, remove clutter folders
.\Install-AgentHub.ps1 -WriteAgents -RemoveUnusedIdeFolders

# Preview changes without writing anything
.\Install-AgentHub.ps1 -DryRun

# Force specific IDE list (skip auto-detection)
.\Install-AgentHub.ps1 -Ides Cursor,VSCode,Kiro -WriteAgents

# One-time migration of legacy/incorrect paths from older script versions
.\Install-AgentHub.ps1 -MigrateLegacyPaths -WriteAgents

# Remove junctions/generated files (safe by default; -Full removes everything Install writes)
.\Uninstall-AgentHub.ps1 -DryRun
.\Uninstall-AgentHub.ps1 -Full

# Audit always-on file sizes across all product roots (flags anything > 2 KB)
.\Inventory-AgentFiles.ps1
```

There are no build, lint, or test commands for this repo — it has no
application code, only scripts/templates/docs. Validate changes by running
`Install-AgentHub.ps1 -DryRun` and `Inventory-AgentFiles.ps1`.

## Key constraint: context hygiene

Always-on agent files (`AGENTS.md`, `.cursorrules`, `*.mdc` pointers,
`.kiro/steering/*.md` in *target* repos) must stay under ~2 KB. Full stack
guides belong exclusively in `skills/*/SKILL.md`, loaded on demand. See
`docs/CONTEXT-HYGIENE.md` for the full policy — never reintroduce a full
stack guide into an always-on file.
