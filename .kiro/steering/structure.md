---
inclusion: always
---

# Project Structure

```
D:\IA\agents/
  catalog/
    projects.json          # roots, family match patterns, skills-per-family, IDE list
  docs/
    CONTEXT-HYGIENE.md     # canonical policy: always-on vs on-demand context, size limits
    superpowers/
      plans/                # implementation plans (dated)
      specs/                # design docs (dated)
  mcp/
    <server>.template.json # MCP config templates with {{PLACEHOLDER}} tokens (JSON-based IDEs)
    <server>.template.toml # same, TOML variant
  scripts/
    Install-AgentHub.ps1    # main entrypoint: detect IDEs, link skills, write AGENTS.md/pointers, write MCP configs
    Uninstall-AgentHub.ps1  # reverse of Install (junctions only by default; -Full for everything)
    Inventory-AgentFiles.ps1 # audits always-on file sizes across product roots
  skills/
    <skill-name>/
      SKILL.md              # on-demand guide with YAML frontmatter (name, description)
  templates/
    agents/                 # slim AGENTS.md templates per family ({{PROJECT}} placeholder)
    antigravity/rules.md    # slim Antigravity pointer template
    copilot/                # slim Copilot instructions per family
    rules/                  # short Cursor .mdc pointer rules (alwaysApply: false)
  README.md                 # setup instructions (Portuguese)
```

## Conventions

- **Skill files** (`skills/<name>/SKILL.md`): YAML frontmatter with `name` +
  `description` (the description drives when an agent should load it), followed
  by the guide body. Stack-specific skills (nestjs/angular/delphi) are written
  in the target repo's convention language; process skills (debug-issue,
  explore-codebase, refactor-safely, review-changes) are short (~1-2 KB) and
  end with a shared "Token Efficiency Rules" section.
- **Family definitions** (`catalog/projects.json`): each family has `match`
  (glob patterns against project folder name), `skills` (list to link),
  `mcp` (extra MCP servers on top of `mcp.common`), `agentsTemplate`,
  `cursorRule`, `extraRules`. Top-level `mcp.common` / `mcp.skipIdes` /
  `mcp.extra` select servers per repo and per IDE. Family resolution order in
  `Install-AgentHub.ps1` is nestjs → angular → delphi → minimal (first match wins).
- **Templates use placeholders**: `{{PROJECT}}`, `{{REPO}}`,
  `{{HUB}}`, `{{CONTEXT7_API_KEY}}` — substituted by `Install-AgentHub.ps1`
  when writing into target repos.
- **Dated docs**: files under `docs/superpowers/plans/` and `specs/` are named
  `YYYY-MM-DD-<slug>.md` and are append-mostly (checklists get ticked, revision
  sections added by date) rather than rewritten.
- **Language**: README and Portuguese-facing docs (CONTEXT-HYGIENE.md) are in
  Portuguese since the target teams are Brazilian; skill bodies match the
  target stack's convention (Delphi/NestJS skills in Portuguese, Angular skill
  in English) — follow the existing language of the file being edited.
- **No junctions committed to Git**: symlinks/junctions created by
  `Install-AgentHub.ps1` in target repos are local-only and must never be
  committed; only the hub's own files and the slim generated `AGENTS.md` /
  IDE pointer files in target repos are versioned.
- **This repo's own `.kiro/`**: only holds steering (this file's directory).
  Do not add a skills junction or MCP config here — those are for *target*
  repos, not the hub itself.
