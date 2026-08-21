# Agent Hub Implementation Plan

> **For agentic workers:** execute sequentially; hub path `D:\IA\agents`.

**Goal:** Hub + install script + slim AGENTS across ERP/NFE/MOBI.

**Tech:** PowerShell junctions (`mklink /J`), skill markdown, MCP JSON templates.

### Task 1: Hub scaffold + skills

- [x] Create folders, extract SKILL.md from former AGENTS guides
- [x] Templates + catalog + MCP template

### Task 2: Scripts

- [x] `Install-AgentHub.ps1`
- [x] `Uninstall-AgentHub.ps1` / `Inventory-AgentFiles.ps1`
- [x] README + design spec

### Task 3: Run install

- [x] `Install-AgentHub.ps1 -WriteAgents -RemoveUnusedIdeFolders`
- [x] Spot-check one NestJS, one Angular, one Delphi repo
- [x] `Inventory-AgentFiles.ps1` shows smaller AGENTS.md
