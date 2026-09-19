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
| delphi | Delphi 12 / VCL, Firebird, FireDAC/UniDAC, ACBr, Horse | `*-erp` |
| android | Java + XML Views (MOBICLASS APKs); skill vendor `claude-android-ninja` | `mobiclass-apk`, `mobiclass-leitor`, `mobiclass-comanda` |
| minimal | fallback, no specific stack | `*` |

Full stack conventions live in `skills/<family>/SKILL.md` — do not duplicate
them into always-on files (see Structure below). Refer users there for
stack-specific coding rules.

## MCP servers (templated in `mcp/*.template.json`, selected by `catalog/projects.json`)

- **codegraph** — native binary (`codegraph serve --mcp --path <repo>`), no runtime dependency. All families.
- **context7** — `npx -y @upstash/context7-mcp`. All families. Optional `CONTEXT7_API_KEY`.
- **filesystem** — `npx -y @modelcontextprotocol/server-filesystem`, scoped to the target repo + hub. All families.
- **mongodb** — `node` + global `mongodb-mcp-server@2` (not `npx`). NestJS family only. Default URI `mongodb://root:password@127.0.0.1:27017/erpclass?authSource=admin`. Override with `$env:MDB_MCP_CONNECTION_STRING` at install.
- **openapi** — `npx -y @ivotoby/openapi-mcp-server --tools dynamic`. NestJS only when `src/main.ts` already has Swagger. Spec URL from local port + `/swagger/json` (or the project's `jsonDocumentUrl`). Omitted from Codex. API must be running. No JWT in git.
- **playwright** — `npx -y @playwright/mcp --headless`. Angular family plus `*-www` / `*-ajuda`. Omitted from Codex (`mcp.skipIdes`).
- **coreui** — `npx -y @coreui/docs-mcp --framework angular`. Angular family. CoreUI component docs (props, events, examples) from coreui.io.
- **chrome-devtools** — `npx -y chrome-devtools-mcp@latest` (headless by default). Angular family plus `*-www` / `*-ajuda`. Live-browser inspection (DOM, console, network, perf traces) for the `frontend-ui-engineering` / `browser-testing-with-devtools` skills. Omitted from Codex (`mcp.skipIdes`). Needs Google Chrome / Chrome for Testing on the machine.

## Supported IDEs/agents

Detected: Cursor, VS Code, Kiro, OpenCode, Antigravity, Claude Code, Codex, Devin
(Qoder is opt-in via `-IncludeQoder`). Per-machine allow/exclude lives in
`D:\AGENTS\.env` (`AGENTHUB_IDES`, `AGENTHUB_EXCLUDE_IDES`); catalog `ides` /
`excludeIdes` is only the fallback when `.env` is missing. Install only writes
for IDEs actually present on the machine (even with explicit `-Ides`; override
with `-AllowMissing`). Skills link as junctions except **Kiro**, which needs
real copies in `.kiro/skills` — so re-run install after editing a skill to
refresh Kiro's copies. See `docs/CONTEXT-HYGIENE.md` Revisão 2026-09-18.

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

# Install/clean a folder anywhere on disk; D:\SISTEMAS is then ignored entirely
.\Install-AgentHub.ps1 -ProjectPath C:\dev\meu-api -WriteAgents

# Remove junctions/generated files (safe by default; -Full removes everything Install writes)
.\Uninstall-AgentHub.ps1 -DryRun
.\Uninstall-AgentHub.ps1 -Full

# Clean reset: drop everything the hub wrote (incl. stale state) and rebuild
.\Uninstall-AgentHub.ps1 -Full -PruneState
.\Install-AgentHub.ps1 -WriteAgents

# Repair state desynchronised by the old CR CR LF writer bug (dry-run default)
python agenthub_repair_state.py --hub .. ; python agenthub_repair_state.py --hub .. --apply

# Audit always-on file sizes across all product roots (flags anything > 2 KB)
.\Inventory-AgentFiles.ps1
```

This repo has no application code, so there is no build or lint step, but it
**does** have tests. Run them before committing:

```powershell
.\Run-Tests.ps1            # pytest + the PowerShell integration tests, one verdict
```

Also validate with `Install-AgentHub.ps1 -DryRun` and `Inventory-AgentFiles.ps1`.
A repeated install must report 0 rewrites and 0 `Preserved ...` warnings; anything
else means the state tracking drifted again (see `docs/CONTEXT-HYGIENE.md`).

## Key constraint: context hygiene

Always-on agent files (`AGENTS.md`, `.cursorrules`, `*.mdc` pointers,
`.kiro/steering/*.md` in *target* repos) must stay under ~2 KB. Full stack
guides belong exclusively in `skills/*/SKILL.md`, loaded on demand. See
`docs/CONTEXT-HYGIENE.md` for the full policy — never reintroduce a full
stack guide into an always-on file.
