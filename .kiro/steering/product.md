---
inclusion: always
---

# Product: AgentHub

AgentHub is the single source of truth for AI coding-agent configuration (skills,
templates, MCP configs, install scripts) shared across four product lines:
**ERPCLASS**, **NFECLASS**, **MOBICLASS**, **SHOPCLASS** (repos live under
`D:\SISTEMAS\<ROOT>\<project>`).

This repo (`D:\IA\agents`) is **not an application** — it's meta-tooling that
generates/links agent context files into other repos. There is no runtime
service, API, or UI to build here.

## Problem it solves

Previously, every repo duplicated full NestJS/Angular/Delphi stack guides
inside always-on files (`AGENTS.md`, `.cursorrules`, IDE rules). This wasted
tokens on every conversation and drifted out of sync across repos.

AgentHub centralizes the fat guides as **on-demand skills** in this hub, and
generates **slim always-on pointers** (< 2 KB) per project that reference the
hub instead of duplicating it.

## Core concepts

- **Hub** (`D:\IA\agents`): canonical skills, templates, MCP templates, catalog, scripts.
- **Family**: a stack profile (`nestjs`, `angular`, `delphi`, `android`, `minimal`) matched
  by project name pattern in `catalog/projects.json`, determining which skills/
  templates/rules get applied to a project.
- **Install**: `scripts/Install-AgentHub.ps1` detects installed IDEs and, per
  project, links skills (via directory junctions), writes slim `AGENTS.md` /
  IDE-native pointer files, and writes MCP server configs.
- **Skills**: on-demand markdown guides (`skills/<name>/SKILL.md`) loaded by
  the agent only when relevant — never duplicated into always-on files.

## Users

Developers working across ERPCLASS/NFECLASS/MOBICLASS/SHOPCLASS repos using
AI coding agents (Cursor, VS Code, Kiro, OpenCode, Antigravity, Claude Code, Codex, Devin). They
edit the hub once and re-run the install script to propagate changes to all
local repos.
