<#
.SYNOPSIS
  Links D:\AGENTS skills into the repos under the D:\SISTEMAS family folders
  listed in catalog/projects.json "roots" (ERPCLASS / NFECLASS / MOBICLASS /
  SHOPCLASS / CRMCLASS).

.DESCRIPTION
  - Detects installed IDEs (Cursor, VS Code, Kiro, OpenCode, Antigravity, Claude Code, Codex, Devin)
  - Mirrors vendor skills into hub skills/, one catalog key per upstream
    package so the provenance of every skill is explicit:
    catalog.addyosmaniSkills, catalog.mattPocockSkills,
    catalog.superpowersSkills. catalog.commonSkills holds the cross-cutting
    skills that are not part of a multi-skill vendor package (standalone
    vendors and native hub skills). All four lists apply to every project.
    Warns when the same skill name is claimed by more than one of those lists
    (hub skills/<name> is a flat namespace: one of the mirrors would win
    silently).
  - Creates junctions from hub skills into each project (and prunes stale
    hub-managed skill junctions no longer assigned to the project)
  - Writes slim AGENTS.md (preserves ## Local section)
  - Generates MCP configs only for detected IDEs (common trio everywhere;
    mongodb + openapi on NestJS APIs that already have Swagger
    (mongodb is node + global mongodb-mcp-server@2, never npx on Windows);
    playwright on Angular/www/ajuda frontends;
    Android family uses the common MCPs only)
  - Optionally removes unused IDE folders (.qoder, .codebuddy)
  - Runs "codegraph init <path>" for projects using the codegraph skill
    that don't have a ".codegraph" folder yet (skip with -SkipCodegraphInit).
    Assumes the codegraph binary is already installed and on PATH (npm i -g
    @colbymchenry/codegraph, or the official installer) — unlike the old
    code-review-graph MCP, codegraph is a self-contained native binary with
    no per-hub Python venv to manage. Does NOT run "codegraph install": that
    CLI subcommand overwrites the merged mcp.json files this script writes.
  - Wires the akitaonrails/ai-memory shared-memory server into every detected
    agent when AI_MEMORY_ENABLED is set in .env (skip with -SkipAiMemory).
    ai-memory is GLOBAL per agent (one HTTP MCP entry + lifecycle hooks in
    ~/.claude.json / ~/.claude/settings.json / Cursor / OpenCode), not a
    per-project mcp.json server — the running server derives the project from
    the agent's working dir. Needs the `ai-memory` CLI on PATH and a running
    server (docker run ... akitaonrails/ai-memory). Optionally pins the
    project slug per repo via -WriteAiMemoryToml (.ai-memory.toml).

.EXAMPLE
  .\Install-AgentHub.ps1 -RemoveUnusedIdeFolders -WriteAgents

.EXAMPLE
  .\Install-AgentHub.ps1 -Ides Cursor,VSCode,Kiro -DryRun

.EXAMPLE
  # One-time cleanup of paths written by older script versions
  # (.antigravity\mcp.json, .opencode\opencode.json, .gemini\GEMINI.md)
  .\Install-AgentHub.ps1 -MigrateLegacyPaths -WriteAgents

.EXAMPLE
  # With ai-memory enabled in .env (AI_MEMORY_ENABLED=1). Also pin the
  # project slug per repo (.ai-memory.toml). -SkipAiMemory turns the wiring off.
  .\Install-AgentHub.ps1 -WriteAgents -WriteAiMemoryToml

.EXAMPLE
  # Install into one repository anywhere on disk. The managed roots under
  # D:\SISTEMAS are not scanned at all.
  .\Install-AgentHub.ps1 -ProjectPath C:\dev\meu-api -WriteAgents

.EXAMPLE
  # Same, but the path only holds repositories: each child is configured.
  .\Install-AgentHub.ps1 -ProjectPath C:\dev -WriteAgents
#>
[CmdletBinding()]
param(
  [string]$HubPath = '',
  [string[]]$Roots = @(),
  # Install into specific folders anywhere on disk, bypassing the managed roots
  # under D:\SISTEMAS entirely. A path that is itself a repository is configured
  # directly; a path that only contains repositories has its children
  # configured. Without this parameter every project under the catalog roots is
  # processed, which is the normal mode.
  [string[]]$ProjectPath = @(),
  [string[]]$Ides = @(),
  [switch]$RemoveUnusedIdeFolders,
  [switch]$WriteAgents,
  [switch]$DryRun,
  [switch]$IncludeQoder,
  [switch]$ForceAgents,
  [switch]$MigrateLegacyPaths,
  [switch]$SkipCodegraphInit,
  [switch]$SkipMattPocockSetup,
  [switch]$SkipAiMemory,
  [switch]$WriteAiMemoryToml,
  [switch]$GlobalSkills,
  [switch]$AdoptLegacyConfigs,
  [switch]$CheckVendorUpdates,
  [switch]$UpdateVendors,
  # By default, an explicit -Ides / AGENTHUB_IDES list is still filtered to the
  # IDEs actually installed on this machine (so carrying the hub elsewhere never
  # writes configs for absent IDEs). Set -AllowMissing to force the given list.
  [switch]$AllowMissing
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'AgentHub.Common.ps1')

function Resolve-HubPath {
  param([string]$Path)
  if ($Path) { return (Resolve-Path $Path).Path }
  $scriptDir = Split-Path -Parent $PSScriptRoot
  if (Test-Path (Join-Path $scriptDir 'skills')) { return $scriptDir }
  $default = 'D:\AGENTS'
  if (Test-Path $default) { return $default }
  throw "Hub not found. Pass -HubPath."
}

function Import-HubDotEnv {
  # Load D:\AGENTS\.env into the process. Already-set env vars win (CI / setx).
  param([string]$HubPath)
  $path = Join-Path $HubPath '.env'
  if (-not (Test-Path -LiteralPath $path)) { return $false }
  foreach ($raw in Get-Content -LiteralPath $path -Encoding UTF8) {
    $line = $raw.Trim()
    if (-not $line -or $line.StartsWith('#')) { continue }
    if ($line -match '^\s*export\s+') { $line = $line -replace '^\s*export\s+', '' }
    $eq = $line.IndexOf('=')
    if ($eq -lt 1) { continue }
    $key = $line.Substring(0, $eq).Trim()
    $val = $line.Substring($eq + 1).Trim()
    if (($val.StartsWith('"') -and $val.EndsWith('"')) -or ($val.StartsWith("'") -and $val.EndsWith("'"))) {
      if ($val.Length -ge 2) { $val = $val.Substring(1, $val.Length - 2) }
    }
    if (-not $key) { continue }
    if ($null -ne [Environment]::GetEnvironmentVariable($key, 'Process')) { continue }
    Set-Item -Path "Env:$key" -Value $val
  }
  return $true
}

function ConvertTo-IdeNameList {
  param([string]$Raw)
  if ($null -eq $Raw) { return @() }
  return @($Raw -split '[,;]' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
}

function Test-ProcessEnvDefined {
  param([string]$Name)
  return ($null -ne [Environment]::GetEnvironmentVariable($Name, 'Process'))
}

function Resolve-IdePolicy {
  # Per-machine lists: process env / .env override catalog/projects.json.
  # AGENTHUB_IDES empty or "auto" = no allowlist (every detected IDE minus exclude).
  param([object]$Catalog)
  $known = @('Cursor', 'VSCode', 'Kiro', 'OpenCode', 'Antigravity', 'Claude', 'Codex', 'Devin', 'Qoder')
  $allowedSource = 'catalog.ides'
  $excludeSource = 'catalog.excludeIdes'
  $allowedIdes = @($Catalog.ides)
  $excludeIdes = @()
  if ($Catalog.excludeIdes) { $excludeIdes = @($Catalog.excludeIdes) }

  if (Test-ProcessEnvDefined -Name 'AGENTHUB_IDES') {
    # @() guard: a function returning an empty array unrolls to $null on the
    # way out, and $null.Count throws under Set-StrictMode.
    $parsed = @(ConvertTo-IdeNameList -Raw $env:AGENTHUB_IDES)
    $allowedSource = '.env AGENTHUB_IDES'
    if ($parsed.Count -eq 0 -or ($parsed.Count -eq 1 -and $parsed[0] -in @('auto', '*'))) {
      $allowedIdes = @()
    } else {
      $allowedIdes = $parsed
    }
  }
  if (Test-ProcessEnvDefined -Name 'AGENTHUB_EXCLUDE_IDES') {
    $excludeIdes = @(ConvertTo-IdeNameList -Raw $env:AGENTHUB_EXCLUDE_IDES)
    $excludeSource = '.env AGENTHUB_EXCLUDE_IDES'
  }

  foreach ($name in @($allowedIdes + $excludeIdes)) {
    if ($name -and $known -notcontains $name) {
      Write-Warning "Unknown IDE name '$name' (valid: $($known -join ', '))"
    }
  }
  return [pscustomobject]@{
    Allowed        = $allowedIdes
    Excluded       = $excludeIdes
    AllowedSource  = $allowedSource
    ExcludedSource = $excludeSource
  }
}

function Get-DetectedIdes {
  param([string[]]$Override, [string[]]$Allowed, [string[]]$Excluded, [switch]$IncludeQoder, [switch]$AllowMissing)
  # Which IDEs actually have a footprint on THIS machine. Used both for
  # auto-detection and to filter an explicit -Ides / AGENTHUB_IDES override, so
  # carrying the hub to a machine that lacks an IDE never writes that IDE's
  # skills/configs (unless -AllowMissing is set to intentionally force it).
  $present = Get-PresentIdes -IncludeQoder:$IncludeQoder

  if ($Override -and $Override.Count -gt 0) {
    $candidates = @($Override | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if (-not $AllowMissing) {
      $missing = @($candidates | Where-Object { $present -notcontains $_ })
      if ($missing.Count -gt 0) {
        Write-Warning ("Ignoring IDEs from -Ides/AGENTHUB_IDES not detected on this machine: {0}. Use -AllowMissing to force." -f ($missing -join ', '))
      }
      $candidates = @($candidates | Where-Object { $present -contains $_ })
    }
    if ($Allowed -and $Allowed.Count -gt 0) {
      $candidates = @($candidates | Where-Object { $Allowed -contains $_ })
    }
    if ($Excluded -and $Excluded.Count -gt 0) {
      $candidates = @($candidates | Where-Object { $Excluded -notcontains $_ })
    }
    return , $candidates
  }
  $candidates = @($present | Select-Object -Unique)
  if ($Allowed -and $Allowed.Count -gt 0) {
    $candidates = @($candidates | Where-Object { $Allowed -contains $_ })
  }
  if ($Excluded -and $Excluded.Count -gt 0) {
    $candidates = @($candidates | Where-Object { $Excluded -notcontains $_ })
  }
  return , $candidates
}

function Get-PresentIdes {
  # Returns the IDE names that have an on-disk / on-PATH footprint on this
  # machine. Single source of truth for "is this IDE installed here".
  param([switch]$IncludeQoder)
  $userHome = $env:USERPROFILE
  $found = [System.Collections.Generic.List[string]]::new()
  if (Test-Path (Join-Path $userHome '.cursor')) { [void]$found.Add('Cursor') }
  # VS Code Stable or Insiders (Insiders uses ~/.vscode-insiders and the
  # `code-insiders` launcher; either footprint counts as VSCode present).
  if ((Test-Path (Join-Path $userHome '.vscode')) -or
      (Test-Path (Join-Path $userHome '.vscode-insiders')) -or
      (Get-Command code -ErrorAction SilentlyContinue) -or
      (Get-Command code-insiders -ErrorAction SilentlyContinue)) {
    [void]$found.Add('VSCode')
  }
  if (Test-Path (Join-Path $userHome '.kiro')) { [void]$found.Add('Kiro') }
  if ((Test-Path (Join-Path $userHome '.antigravity')) -or
      (Test-Path (Join-Path $env:APPDATA 'Antigravity')) -or
      (Test-Path (Join-Path $userHome '.gemini')) -or
      (Get-Command agy -ErrorAction SilentlyContinue) -or
      (Get-Command antigravity -ErrorAction SilentlyContinue)) {
    [void]$found.Add('Antigravity')
  }
  if ($IncludeQoder -and (Test-Path (Join-Path $userHome '.qoder'))) { [void]$found.Add('Qoder') }
  if ((Test-Path (Join-Path $userHome '.config\opencode\opencode.json')) -or
      (Test-Path (Join-Path $userHome '.opencode')) -or
      (Get-Command opencode -ErrorAction SilentlyContinue)) {
    [void]$found.Add('OpenCode')
  }
  if ((Test-Path (Join-Path $userHome '.claude')) -or
      (Get-Command claude -ErrorAction SilentlyContinue)) {
    [void]$found.Add('Claude')
  }
  if ((Test-Path (Join-Path $userHome '.codex')) -or
      (Get-Command codex -ErrorAction SilentlyContinue)) {
    [void]$found.Add('Codex')
  }
  if ((Test-Path (Join-Path $userHome '.devin')) -or
      (Test-Path (Join-Path $env:APPDATA 'devin')) -or
      (Get-Command devin -ErrorAction SilentlyContinue)) {
    [void]$found.Add('Devin')
  }
  return , @($found | Select-Object -Unique)
}

function Assert-NoSkillNameCollisions {
  # Fails before anything is written when two catalog lists claim the same
  # skill name. Each list is mirrored into hub skills/<name> in turn, so a
  # shared name means the later mirror repoints the junction and every project
  # silently gets the other package's content. Cheap, deterministic, and does
  # not need the vendor clones - so it also works on a fresh machine and under
  # -DryRun. Duplicates *within* one list are harmless (they dedupe) and are
  # ignored here.
  param([System.Collections.Specialized.OrderedDictionary]$Lists)
  $owners = [ordered]@{}
  foreach ($entry in $Lists.GetEnumerator()) {
    foreach ($name in @($entry.Value | Select-Object -Unique)) {
      if (-not $name) { continue }
      if (-not $owners.Contains($name)) { $owners[$name] = @() }
      $owners[$name] += $entry.Key
    }
  }
  $conflicts = @($owners.GetEnumerator() | Where-Object { $_.Value.Count -gt 1 })
  if ($conflicts.Count -eq 0) { return }
  $detail = @($conflicts | ForEach-Object {
    # Mirrors run in list order, so the last claimant is the one that wins.
    "$($_.Key) claimed by $($_.Value -join ', ') (would resolve to $(@($_.Value)[-1]))"
  })
  throw "Skill name claimed by more than one catalog list: $($detail -join '; '). hub skills/<name> can only point at one package - keep each name in a single list."
}

function Ensure-VendorAgentSkills {
  # Clone or init the addyosmani/agent-skills submodule used by
  # catalog.addyosmaniSkills.
  param([string]$HubPath, [switch]$DryRun)
  $vendor = Join-Path $HubPath 'vendor\addyosmani-agent-skills'
  $url = 'https://github.com/addyosmani/agent-skills.git'
  if (Test-Path (Join-Path $vendor 'skills')) { return $vendor }
  if ($DryRun) {
    Write-Host "  [dry] clone $url -> $vendor"
    return $vendor
  }
  $parent = Split-Path -Parent $vendor
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  Push-Location $HubPath
  try {
    if (Test-Path (Join-Path $HubPath '.gitmodules')) {
      git submodule update --init --recursive -- vendor/addyosmani-agent-skills 2>$null | Out-Null
    }
  } finally {
    Pop-Location
  }
  if (-not (Test-Path (Join-Path $vendor 'skills'))) {
    Write-Host "Cloning $url -> $vendor"
    git clone --depth 1 $url $vendor
  }
  # Validate that the vendor skills are actually available after all attempts
  if (-not (Test-Path (Join-Path $vendor 'skills'))) {
    Write-Warning "Vendor skills unavailable: git submodule/clone failed for $url. Vendor-based skills will be skipped."
    return $null
  }
  return $vendor
}

function Ensure-VendorSkillMirrors {
  # Junctions from hub skills/ + references/ into the vendor clone.
  # These paths are gitignored; this function is what makes a fresh clone usable.
  param([string]$HubPath, [string[]]$SkillNames, [switch]$DryRun)
  if (-not $SkillNames -or $SkillNames.Count -eq 0) { return }
  $vendor = Ensure-VendorAgentSkills -HubPath $HubPath -DryRun:$DryRun
  if (-not $vendor) { return }
  foreach ($name in $SkillNames) {
    $target = Join-Path $vendor "skills\$name"
    if (-not (Test-Path $target)) {
      Write-Warning "Vendor skill missing: $target"
      continue
    }
    New-JunctionOrCopy -LinkPath (Join-Path $HubPath "skills\$name") -TargetPath $target -DryRun:$DryRun
  }
  $refTarget = Join-Path $vendor 'references'
  if (Test-Path $refTarget) {
    New-JunctionOrCopy -LinkPath (Join-Path $HubPath 'references') -TargetPath $refTarget -DryRun:$DryRun
  }
}

function Ensure-VendorStandaloneSkill {
  # Clone or init a vendor skill whose SKILL.md lives at the vendor root
  # (not under vendor/skills/<name>). Junctions hub skills/<name> -> vendor.
  param(
    [string]$HubPath,
    [string]$SkillName,
    [string]$VendorRelativePath,
    [string]$Url,
    [switch]$DryRun
  )
  $vendor = Join-Path $HubPath ($VendorRelativePath -replace '/', '\')
  $skillMd = Join-Path $vendor 'SKILL.md'
  if (-not (Test-Path $skillMd)) {
    if ($DryRun) {
      Write-Host "  [dry] clone $Url -> $vendor"
    } else {
      $parent = Split-Path -Parent $vendor
      if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
      Push-Location $HubPath
      try {
        if (Test-Path (Join-Path $HubPath '.gitmodules')) {
          git submodule update --init --recursive -- $VendorRelativePath 2>$null | Out-Null
        }
      } finally {
        Pop-Location
      }
      if (-not (Test-Path $skillMd)) {
        Write-Host "Cloning $Url -> $vendor"
        git clone --depth 1 $Url $vendor
      }
    }
  }
  if (-not (Test-Path $skillMd)) {
    Write-Warning "Standalone vendor skill unavailable: $Url ($VendorRelativePath)"
    return
  }
  New-JunctionOrCopy -LinkPath (Join-Path $HubPath "skills\$SkillName") -TargetPath $vendor -DryRun:$DryRun
}

function Select-VendorProvidedSkills {
  # Which of the candidate skill names does this vendor clone actually provide?
  # Lets a vendor skill be assigned through a family's "skills" list, not just
  # the top-level vendor list, without hardcoding a second copy of the mapping:
  # the folder that holds SKILL.md is the source of truth for provenance.
  # Silent when the clone is missing (a fresh machine mirrors on the declared
  # list first, then re-resolves); never invents names the vendor lacks.
  param(
    [string]$HubPath,
    [string]$VendorRelativePath,
    [System.Collections.IEnumerable]$Candidates,
    [switch]$Nested  # mattpocock nests one level: skills/<category>/<name>
  )
  $skillsRoot = Join-Path (Join-Path $HubPath ($VendorRelativePath -replace '/', '\')) 'skills'
  if (-not (Test-Path $skillsRoot)) { return }
  $provided = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
  $searchDepth = if ($Nested) { 2 } else { 1 }
  foreach ($md in Get-ChildItem $skillsRoot -Recurse -Depth $searchDepth -Filter 'SKILL.md' -File -ErrorAction SilentlyContinue) {
    [void]$provided.Add($md.Directory.Name)
  }
  foreach ($name in $Candidates) {
    if ($name -and $provided.Contains($name)) { $name }
  }
}

function Get-MattPocockSkillPath {
  # mattpocock/skills nests skills one level deeper: skills/<category>/<name>.
  # Resolve the category folder dynamically so catalog entries stay plain names.
  param([string]$VendorRoot, [string]$SkillName)
  $skillsRoot = Join-Path $VendorRoot 'skills'
  if (-not (Test-Path $skillsRoot)) { return $null }
  foreach ($category in Get-ChildItem $skillsRoot -Directory) {
    $candidate = Join-Path $category.FullName $SkillName
    if (Test-Path (Join-Path $candidate 'SKILL.md')) { return $candidate }
  }
  return $null
}

function Ensure-VendorMattPocockSkillMirrors {
  # Clone or init the mattpocock/skills submodule and junction each
  # catalog.mattPocockSkills entry from hub skills/<name> into the vendor
  # clone. Hub-side junctions are gitignored; this is what makes them usable.
  param([string]$HubPath, [string[]]$SkillNames, [switch]$DryRun)
  if (-not $SkillNames -or $SkillNames.Count -eq 0) { return }
  $vendor = Join-Path $HubPath 'vendor\mattpocock-skills'
  $url = 'https://github.com/mattpocock/skills.git'
  if (-not (Test-Path (Join-Path $vendor 'skills'))) {
    if ($DryRun) {
      Write-Host "  [dry] clone $url -> $vendor"
      foreach ($name in $SkillNames) { Write-Host "  [dry] junction $(Join-Path $HubPath "skills\$name") -> $vendor\skills\<category>\$name" }
      return
    }
    $parent = Split-Path -Parent $vendor
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    Push-Location $HubPath
    try {
      if (Test-Path (Join-Path $HubPath '.gitmodules')) {
        git submodule update --init --recursive -- vendor/mattpocock-skills 2>$null | Out-Null
      }
    } finally {
      Pop-Location
    }
    if (-not (Test-Path (Join-Path $vendor 'skills'))) {
      Write-Host "Cloning $url -> $vendor"
      git clone --depth 1 $url $vendor
    }
  }
  if (-not (Test-Path (Join-Path $vendor 'skills'))) {
    Write-Warning "mattpocock/skills unavailable: git submodule/clone failed for $url. mattPocockSkills will be skipped."
    return
  }
  foreach ($name in $SkillNames) {
    $target = Get-MattPocockSkillPath -VendorRoot $vendor -SkillName $name
    if (-not $target) {
      Write-Warning "mattpocock skill missing: $name (looked under $vendor\skills\*\$name)"
      continue
    }
    New-JunctionOrCopy -LinkPath (Join-Path $HubPath "skills\$name") -TargetPath $target -DryRun:$DryRun
  }
}

function Ensure-VendorSuperpowersSkillMirrors {
  # Clone or init the obra/superpowers submodule and junction each
  # catalog.superpowersSkills entry from hub skills/<name> into the vendor
  # clone. superpowers stores skills flat at skills/<name>/SKILL.md (same
  # layout as addyosmani, unlike mattpocock's skills/<category>/<name>).
  # Hub-side junctions are gitignored; this is what makes them usable.
  param([string]$HubPath, [string[]]$SkillNames, [switch]$DryRun)
  if (-not $SkillNames -or $SkillNames.Count -eq 0) { return }
  $vendor = Join-Path $HubPath 'vendor\superpowers'
  $url = 'https://github.com/obra/superpowers.git'
  if (-not (Test-Path (Join-Path $vendor 'skills'))) {
    if ($DryRun) {
      Write-Host "  [dry] clone $url -> $vendor"
      foreach ($name in $SkillNames) { Write-Host "  [dry] junction $(Join-Path $HubPath "skills\$name") -> $vendor\skills\$name" }
      return
    }
    $parent = Split-Path -Parent $vendor
    if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
    Push-Location $HubPath
    try {
      if (Test-Path (Join-Path $HubPath '.gitmodules')) {
        git submodule update --init --recursive -- vendor/superpowers 2>$null | Out-Null
      }
    } finally {
      Pop-Location
    }
    if (-not (Test-Path (Join-Path $vendor 'skills'))) {
      Write-Host "Cloning $url -> $vendor"
      git clone --depth 1 $url $vendor
    }
  }
  if (-not (Test-Path (Join-Path $vendor 'skills'))) {
    Write-Warning "obra/superpowers unavailable: git submodule/clone failed for $url. superpowersSkills will be skipped."
    return
  }
  foreach ($name in $SkillNames) {
    $target = Join-Path $vendor "skills\$name"
    if (-not (Test-Path (Join-Path $target 'SKILL.md'))) {
      Write-Warning "superpowers skill missing: $name (looked under $vendor\skills\$name)"
      continue
    }
    New-JunctionOrCopy -LinkPath (Join-Path $HubPath "skills\$name") -TargetPath $target -DryRun:$DryRun
  }
}

function Get-IdeRegistry {
  # THE authoritative map of where each agent keeps its project-level files.
  # Install, uninstall, the sync scripts and the diagnostics all read this, so
  # adding an agent or fixing a path is one edit here instead of eight copies
  # that silently drift apart.
  #   Skills     - directory the agent discovers project skills in
  #   Mcp        - project MCP config file
  #   Property   - JSON property holding the server map, or 'toml'
  #   CopySkills - agent does not follow directory junctions (Kiro), so copy
  return [ordered]@{
    Cursor      = @{ Skills = '.cursor/skills';   Mcp = '.cursor/mcp.json';        Property = 'mcpServers'; CopySkills = $false }
    VSCode      = @{ Skills = '.github/skills';   Mcp = '.vscode/mcp.json';        Property = 'servers';    CopySkills = $false }
    Kiro        = @{ Skills = '.kiro/skills';     Mcp = '.kiro/settings/mcp.json'; Property = 'mcpServers'; CopySkills = $true  }
    Claude      = @{ Skills = '.claude/skills';   Mcp = '.mcp.json';               Property = 'mcpServers'; CopySkills = $false }
    Codex       = @{ Skills = '.agents/skills';   Mcp = '.codex/config.toml';      Property = 'toml';       CopySkills = $false }
    Antigravity = @{ Skills = '.agents/skills';   Mcp = '.agents/mcp_config.json'; Property = 'mcpServers'; CopySkills = $false }
    OpenCode    = @{ Skills = '.opencode/skills'; Mcp = 'opencode.json';           Property = 'mcp';        CopySkills = $false }
    Devin       = @{ Skills = '.devin/skills';    Mcp = '.devin/mcp_config.json';  Property = 'mcpServers'; CopySkills = $false }
    Qoder       = @{ Skills = '.qoder/skills';    Mcp = '.qoder/mcp.json';         Property = 'mcpServers'; CopySkills = $false }
  }
}

function Get-IdeSkillRoots {
  # Distinct skill roots for the given IDEs, carrying whether each must be
  # populated by copy. Codex and Antigravity deliberately share .agents/skills,
  # so the result is de-duplicated by path.
  param([string[]]$Ides)
  $registry = Get-IdeRegistry
  $roots = [ordered]@{}
  foreach ($ide in $Ides) {
    if (-not $registry.Contains($ide)) { continue }
    $entry = $registry[$ide]
    if ($roots.Contains($entry.Skills)) {
      if ($entry.CopySkills) { $roots[$entry.Skills] = $true }
      continue
    }
    $roots[$entry.Skills] = [bool]$entry.CopySkills
  }
  return $roots
}

function Test-ProjectDirectory {
  # Does this folder look like a repository the hub should configure? Android
  # trees are included even when the git root only wraps src/ or Android Studio
  # metadata, which is why the resolved family is taken into account.
  param([string]$Path, [string]$Family = '')
  foreach ($marker in @('AGENTS.md', 'src', 'source', 'package.json', '.git',
                        'settings.gradle', 'settings.gradle.kts', 'build.gradle', 'app')) {
    if (Test-Path (Join-Path $Path $marker)) { return $true }
  }
  return ($Family -eq 'android')
}

function Get-CatalogFamilies {
  # Single source of truth for the family table, in the order the catalog
  # declares it. An ordinary hashtable does not preserve order, which is why
  # family precedence used to live in a hardcoded list in the code instead of
  # in catalog/projects.json.
  param([object]$Catalog)
  $families = [ordered]@{}
  foreach ($prop in $Catalog.families.PSObject.Properties) { $families[$prop.Name] = $prop.Value }
  return $families
}

function Get-UniversalSkillLists {
  # The catalog lists that apply to every project, keyed by catalog property so
  # the provenance of a skill is a lookup rather than a guess. One key per
  # upstream multi-skill package; commonSkills holds the cross-cutting skills
  # that do not belong to one (standalone vendors, native hub skills). Order is
  # mirror order, which is also collision-resolution order.
  param([object]$Catalog)
  $lists = [ordered]@{}
  foreach ($key in @('commonSkills', 'addyosmaniSkills', 'mattPocockSkills', 'superpowersSkills')) {
    $lists["catalog.$key"] = @(Get-JsonProperty $Catalog $key)
  }
  return $lists
}

function Get-ProjectSkillNames {
  # Single source of truth for "which skills does this project get": the
  # universal lists minus the family opt-outs, plus the family's own skills and
  # the ECC adapters that match. Install and Test-AgentHub used to assemble
  # this expression separately, so adding a catalog list made the audit report
  # skills as missing that were never meant to be there.
  param([object]$Catalog, [object]$FamilyCfg, [string]$Family, [string]$ProjectName)
  # disabledCommonSkills opts a family out of the universal lists - all of
  # them, not just commonSkills. Before the vendor lists were split apart,
  # "common" was simply where the Addy Osmani selection happened to live, so
  # the filter silently covered more ground than its name suggests.
  $disabled = @(Get-JsonProperty $FamilyCfg 'disabledCommonSkills')
  $names = [System.Collections.Generic.List[string]]::new()
  foreach ($list in (Get-UniversalSkillLists -Catalog $Catalog).Values) {
    foreach ($name in @($list)) {
      if ($name -and $disabled -notcontains $name) { $names.Add($name) }
    }
  }
  foreach ($name in @($FamilyCfg.skills)) { if ($name) { $names.Add($name) } }
  foreach ($name in @(Get-EccSkillNames -Catalog $Catalog -Family $Family -ProjectName $ProjectName)) {
    $names.Add($name)
  }
  return @($names | Select-Object -Unique)
}

function Get-ProjectFamily {
  param([string]$Name, [System.Collections.IDictionary]$Families, [string]$RepoPath, [object]$Overrides)
  if ($Overrides) {
    $entry = $Overrides.PSObject.Properties[$Name]
    if ($entry) {
      # Contains, not ContainsKey: IDictionary is satisfied by both Hashtable
      # and the OrderedDictionary that Get-CatalogFamilies returns, and only
      # the former has ContainsKey.
      if (-not $Families.Contains([string]$entry.Value)) { throw "Unknown family override for $Name" }
      return [string]$entry.Value
    }
  }
  if ($RepoPath) {
    if (Test-Path (Join-Path $RepoPath 'angular.json')) { return 'angular' }
    $package = Join-Path $RepoPath 'package.json'
    if (Test-Path $package) {
      $json = Get-Content $package -Raw | ConvertFrom-Json
      foreach ($field in @('dependencies', 'devDependencies')) {
        $deps = $json.PSObject.Properties[$field]
        if ($deps -and $deps.Value.PSObject.Properties['@angular/core']) { return 'angular' }
      }
      foreach ($field in @('dependencies', 'devDependencies')) {
        $deps = $json.PSObject.Properties[$field]
        if ($deps -and $deps.Value.PSObject.Properties['@nestjs/core']) { return 'nestjs' }
      }
    }
  }
  # Match in catalog order, but always leave a catch-all ("*") for last no
  # matter where it is declared: otherwise a family declared above it could
  # never be reached. Adding a family to the catalog is now enough - no code
  # change - and removing one cannot leave a dangling name behind.
  $catchAll = $null
  foreach ($key in $Families.Keys) {
    $patterns = @($Families[$key].match)
    if ($patterns -contains '*') {
      if (-not $catchAll) { $catchAll = $key }
      continue
    }
    foreach ($pattern in $patterns) { if ($Name -like $pattern) { return $key } }
  }
  if ($catchAll) { return $catchAll }
  return 'minimal'
}

function Test-SkillTargetHasContent {
  # Guards against silently linking an empty/corrupted skill directory into
  # every project. A skill target is a directory that should contain at
  # least one non-empty file (normally SKILL.md); "references" is a plain
  # folder of checklists, not a single skill, so any non-empty file counts.
  # A directory containing only a ".gitkeep" placeholder (an
  # intentionally-empty skill stub) is treated as valid.
  param([string]$TargetPath)
  if (-not (Test-Path $TargetPath -PathType Container)) { return $true } # not a dir mirror case, let caller handle
  $files = @(Get-ChildItem -Path $TargetPath -Recurse -File -Force -ErrorAction SilentlyContinue)
  if ($files.Count -eq 0) { return $false }
  $realFiles = @($files | Where-Object { $_.Name -ne '.gitkeep' })
  if ($realFiles.Count -eq 0) { return $true } # placeholder-only stub, intentional
  $totalBytes = ($realFiles | Measure-Object -Property Length -Sum).Sum
  return ($totalBytes -gt 0)
}

function Test-CopyUpToDate {
  # True when $LinkPath already holds a byte-identical copy of $TargetPath.
  # Copy-based roots (Kiro) would otherwise delete and re-copy every skill on
  # every run - the single biggest source of I/O and of churned mtimes.
  param([string]$LinkPath, [string]$TargetPath)
  if (-not (Test-Path -LiteralPath $LinkPath -PathType Container)) { return $false }
  $marker = Join-Path $LinkPath '.agenthub-managed'
  if (-not (Test-Path -LiteralPath $marker)) { return $false }
  $srcRoot = (Resolve-Path -LiteralPath $TargetPath).Path.TrimEnd('\')
  $dstRoot = (Resolve-Path -LiteralPath $LinkPath).Path.TrimEnd('\')
  $src = @(Get-ChildItem -LiteralPath $srcRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne '.agenthub-managed' })
  $dst = @(Get-ChildItem -LiteralPath $dstRoot -Recurse -File -Force -ErrorAction SilentlyContinue |
    Where-Object { $_.Name -ne '.agenthub-managed' })
  if ($src.Count -ne $dst.Count) { return $false }
  $dstMap = @{}
  foreach ($f in $dst) { $dstMap[$f.FullName.Substring($dstRoot.Length).TrimStart('\')] = $f }
  foreach ($f in $src) {
    $rel = $f.FullName.Substring($srcRoot.Length).TrimStart('\')
    if (-not $dstMap.ContainsKey($rel)) { return $false }
    $other = $dstMap[$rel]
    if ($other.Length -ne $f.Length) { return $false }
    if ((Get-FileHash -LiteralPath $f.FullName -Algorithm SHA256).Hash -ne
        (Get-FileHash -LiteralPath $other.FullName -Algorithm SHA256).Hash) { return $false }
  }
  return $true
}

function Get-VendorPackageName {
  # <hub>\vendor\<package>\... -> <package>. Returns $null for anything else,
  # which is how callers tell a vendor mirror apart from a native hub skill or
  # a project-side link.
  param([string]$Path, [string]$HubPath)
  if (-not $Path -or -not $HubPath) { return $null }
  $root = [IO.Path]::GetFullPath((Join-Path $HubPath 'vendor')).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
  $full = try { [IO.Path]::GetFullPath($Path) } catch { return $null }
  if (-not $full.StartsWith($root, [StringComparison]::OrdinalIgnoreCase)) { return $null }
  return ($full.Substring($root.Length) -split '[\\/]')[0]
}

function New-JunctionOrCopy {
  param([string]$LinkPath, [string]$TargetPath, [switch]$DryRun, [switch]$ForceCopy)
  if (-not (Test-Path $TargetPath)) {
    Write-Warning "Missing skill target: $TargetPath"
    return
  }
  if ((Test-Path $TargetPath -PathType Container) -and -not (Test-SkillTargetHasContent -TargetPath $TargetPath)) {
    Write-Warning "Skill target is empty (0 bytes of content): $TargetPath -- refusing to link $LinkPath. Fix the source (e.g. 'git checkout -- <path>' in the hub or vendor submodule) and re-run."
    return
  }
  # Already an identical hub-owned copy: nothing to do. Checked before any
  # removal so a copy root stays idempotent instead of re-copying every run.
  if ($ForceCopy -and (Test-CopyUpToDate -LinkPath $LinkPath -TargetPath $TargetPath)) { return }
  $parent = Split-Path -Parent $LinkPath
  if (-not (Test-Path $parent)) {
    if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  }
  if (Test-Path $LinkPath) {
    $item = Get-Item $LinkPath -Force
    $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    if ($isReparse) {
      # A junction exists but we now need a real copy (ForceCopy): remove it.
      if ($ForceCopy) {
        if (-not (Test-HubOwnedLink -Path $LinkPath -HubPath $HubPath)) { Write-Warning "Preserved external link: $LinkPath"; return }
        Remove-HubLink -Path $LinkPath -Root $parent -HubPath $HubPath
      }
      else {
        if (@($item.Target) -contains $TargetPath) { return }
        # Second line of defence behind Assert-NoSkillNameCollisions: that check
        # only sees the catalog, so it cannot catch a name that moved between
        # upstream packages. Repointing from one vendor package to another is
        # never routine - say so instead of swapping the content in silence.
        $fromVendor = Get-VendorPackageName -Path (@($item.Target) | Select-Object -First 1) -HubPath $HubPath
        $toVendor = Get-VendorPackageName -Path $TargetPath -HubPath $HubPath
        if ($fromVendor -and $toVendor -and $fromVendor -ne $toVendor) {
          Write-Warning "Skill name disputed between vendor packages: $LinkPath was $fromVendor, now $toVendor. Confirm which package should own this name in catalog/projects.json."
        }
        if (-not (Test-HubOwnedLink -Path $LinkPath -HubPath $HubPath)) { Write-Warning "Preserved external link: $LinkPath"; return }
        if (-not $DryRun) {
          Remove-HubLink -Path $LinkPath -Root $parent -HubPath $HubPath
          if (Test-Path $LinkPath) {
            Write-Warning "Failed to remove existing junction at $LinkPath - skipping."
            return
          }
        }
      }
    } else {
      # Real directory (not a junction). Only remove if it contains the
      # .agenthub-managed marker written by a previous Copy fallback.
      $markerPath = Join-Path $LinkPath '.agenthub-managed'
      if (-not (Test-Path $markerPath)) {
        Write-Warning "Existing directory at $LinkPath is not hub-managed (no .agenthub-managed marker). Skipping to avoid data loss. Remove manually if unneeded."
        return
      }
      # ForceCopy always refreshes; a plain fallback copy that already matches
      # would be re-copied harmlessly. Remove and recopy to pick up edits.
      if (-not $DryRun) { Remove-HubLink -Path $LinkPath -Root $parent -HubPath $HubPath }
    }
  }
  if ($DryRun) {
    Write-Host ('  [dry] {0} {1} -> {2}' -f $(if ($ForceCopy) {'copy'} else {'junction'}), $LinkPath, $TargetPath)
    return
  }
  # Kiro (and any agent that doesn't follow reparse points) can't read skills
  # through a junction, so copy the folder instead of linking. The copy carries
  # a .agenthub-managed marker so future runs treat it as hub-owned.
  if ($ForceCopy) {
    Copy-Item $TargetPath $LinkPath -Recurse -Force
    Set-Content -Path (Join-Path $LinkPath '.agenthub-managed') -Value "Created by Install-AgentHub.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm'). Safe to delete this folder." -Encoding UTF8
    Write-Host "  copied $LinkPath"
    return
  }
  $ok = $true
  try { New-Item -ItemType Junction -Path $LinkPath -Target $TargetPath -ErrorAction Stop | Out-Null }
  catch {
    Write-Warning "Junction failed for $LinkPath - copying instead."
    Copy-Item $TargetPath $LinkPath -Recurse -Force
    # Write marker so future runs know this copy belongs to the hub
    Set-Content -Path (Join-Path $LinkPath '.agenthub-managed') -Value "Created by Install-AgentHub.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm'). Safe to delete this folder." -Encoding UTF8
    $ok = $false
  }
  if ($ok) { Write-Host "  linked $LinkPath" }
}

function Ensure-CodegraphInit {
  # Runs "codegraph init <path>" for projects that use the codegraph skill
  # and don't have an index yet. Deliberately does NOT call "codegraph
  # install" here: that CLI command auto-configures editor MCP configs
  # directly, overwriting the family-scoped MCP set that Write-McpConfigs
  # already wrote.
  param(
    [string]$RepoPath,
    [string[]]$Skills,
    [switch]$Force,
    [switch]$DryRun
  )
  if ($Skills -notcontains 'codegraph') { return }
  $graphDir = Join-Path $RepoPath '.codegraph'
  if ((Test-Path (Join-Path $graphDir 'codegraph.db')) -and -not $Force) { return }
  if ($DryRun) {
    Write-Host "  [dry] codegraph init `"$RepoPath`""
    return
  }
  $codegraphExe = Get-CodegraphExe
  if (-not $codegraphExe) {
    Write-Warning "  codegraph not found; skipping index init for $RepoPath"
    return
  }
  Write-Host "  initializing codegraph index for $RepoPath ..."
  $previousDoNotTrack = [Environment]::GetEnvironmentVariable('DO_NOT_TRACK', 'Process')
  try {
    $env:DO_NOT_TRACK = '1'
    & $codegraphExe init $RepoPath --yes
    $initExit = $LASTEXITCODE
  } finally {
    [Environment]::SetEnvironmentVariable('DO_NOT_TRACK', $previousDoNotTrack, 'Process')
  }
  if ($initExit -ne 0) {
    Write-Warning "  codegraph init failed for $RepoPath (exit $initExit)"
    return
  }
  $gitignore = Join-Path $RepoPath '.gitignore'
  $entry = '.codegraph/'
  if (Test-Path $gitignore) {
    $lines = Get-Content $gitignore -Encoding UTF8
    if ($lines -notcontains $entry) {
      Add-Content -Path $gitignore -Value $entry -Encoding UTF8
    }
  } else {
    Set-Content -Path $gitignore -Value $entry -Encoding UTF8
  }
}

function Get-LocalSection {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $null }
  $raw = Get-Content $Path -Raw -Encoding UTF8
  $idx = $raw.IndexOf("## Local")
  if ($idx -lt 0) { return $null }
  return $raw.Substring($idx).TrimEnd()
}

function Write-AgentsFile {
  param(
    [string]$RepoPath,
    [string]$ProjectName,
    [string]$TemplatePath,
    [switch]$Force,
    [switch]$DryRun
  )
  $dest = Join-Path $RepoPath 'AGENTS.md'
  $local = $null
  if ((Test-Path $dest) -and -not $Force) {
    $local = Get-LocalSection -Path $dest
  }
  $content = (Get-Content $TemplatePath -Raw -Encoding UTF8).Replace('{{PROJECT}}', $ProjectName)
  if ($local) {
    # drop template Local and append preserved
    $content = [regex]::Replace($content, '(?s)## Local\s*\r?\n.*$', '').TrimEnd() + "`r`n`r`n" + $local + "`r`n"
  }
  if ($DryRun) {
    $kb = [math]::Round($content.Length / 1KB, 1)
    Write-Host ('  [dry] write AGENTS.md sizeKb=' + $kb)
    return
  }
  $efficiency = [regex]::Match($content, '(?s)(## Eficiência de execução\r?\n.*?)(?=\r?\n## Skills\b)').Groups[1].Value.TrimEnd()
  $request = @{path=$dest; format='text'; text=$content; adopt=[bool]$AdoptLegacyConfigs; dry=[bool]$DryRun}
  if ($efficiency) {
    $request.text_patch = @{
      marker = '## Eficiência de execução'
      anchor = '^## Skills\b'
      content = $efficiency
    }
  }
  Invoke-HubConfig $request
  Write-Host "  wrote AGENTS.md"
}

function Write-DesignUiFile {
  # Slim per-project pointer to the coreui-styling skill. The pointer body is
  # hub-managed; the "## Exceções" section below is project-owned. Uses the same
  # anchored text_patch mechanism as AGENTS.md: on a fresh file the whole text is
  # written and owned; once a developer edits the exceptions the file stops being
  # owned, and the patch becomes a no-op (marker already present) instead of
  # emitting a permanent "Preserved manual file" warning.
  param(
    [string]$RepoPath,
    [string]$ProjectName,
    [string]$TemplatePath,
    [switch]$Force,
    [switch]$DryRun
  )
  if (-not (Test-Path $TemplatePath)) { return }
  $dest = Join-Path $RepoPath 'docs\design_ui.md'
  $content = (Get-Content $TemplatePath -Raw -Encoding UTF8).Replace('{{PROJECT}}', $ProjectName)
  if ($DryRun) {
    $kb = [math]::Round($content.Length / 1KB, 1)
    Write-Host ('  [dry] write docs/design_ui.md sizeKb=' + $kb)
    return
  }
  $docsDir = Join-Path $RepoPath 'docs'
  if (-not (Test-Path $docsDir)) { New-Item -ItemType Directory -Path $docsDir -Force | Out-Null }
  # Managed pointer = everything above the exceptions heading; that heading is
  # the anchor and stays project-owned below it.
  $body = [regex]::Replace($content, '(?s)\r?\n## Exceções.*$', '').TrimEnd()
  Invoke-HubConfig @{
    path=$dest; format='text'; text=$content; adopt=[bool]$AdoptLegacyConfigs; dry=[bool]$DryRun
    text_patch=@{ marker='# Design UI —'; anchor='^## Exceções documentadas deste projeto\b'; content=$body }
  }
  Write-Host "  wrote docs/design_ui.md"
}

function Get-RepoOriginUrl {
  param([string]$RepoPath)
  # Some managed folders (for example static help sites) are not Git clones.
  # Avoid invoking git there: with ErrorActionPreference=Stop its stderr would
  # abort the whole installer before the local-tracker fallback can run.
  if (-not (Test-Path -LiteralPath (Join-Path $RepoPath '.git'))) { return '' }
  $result = @(git -C $RepoPath remote get-url origin 2>$null)
  if ($LASTEXITCODE -ne 0 -or $result.Count -eq 0) { return '' }
  return [string]$result[0]
}

function Set-FileFromTemplateIfMissing {
  param(
    [string]$Destination,
    [string]$Template,
    [switch]$DryRun
  )
  if (Test-Path -LiteralPath $Destination) { return $false }
  if (-not (Test-Path -LiteralPath $Template)) {
    throw "Matt Pocock setup template not found: $Template"
  }
  if ($DryRun) {
    Write-Host "  [dry] setup Matt Pocock: write $Destination"
    return $true
  }
  Write-HubText -Path $Destination -Content (Get-Content -LiteralPath $Template -Raw -Encoding UTF8)
  return $true
}

function Update-MattPocockAgentSkillsBlock {
  param([string]$RepoPath, [switch]$TriageInstalled, [switch]$DryRun)
  $agentsPath = Join-Path $RepoPath 'AGENTS.md'
  if (-not (Test-Path -LiteralPath $agentsPath)) {
    Write-Warning "  Matt Pocock setup: AGENTS.md is missing in $RepoPath; docs were configured but the pointer block was not written. Re-run with -WriteAgents."
    return $false
  }

  # Backticks are doubled: inside a double-quoted here-string a single backtick
  # is PowerShell's escape character and would be swallowed, emitting the paths
  # as plain text instead of markdown code spans.
  $triageSection = ''
  if ($TriageInstalled) {
    $triageSection = @'

### Triage labels

Uses the default Matt Pocock label vocabulary. See `docs/agents/triage-labels.md`.
'@
  }
  $block = @"
## Agent skills

### Issue tracker

Issues and specs use the configured tracker. See ``docs/agents/issue-tracker.md``.
$triageSection

### Domain docs

Single-context layout at the repository root. See ``docs/agents/domain.md``.
"@
  $block = $block.TrimEnd()

  $raw = Get-Content -LiteralPath $agentsPath -Raw -Encoding UTF8
  $pattern = '(?ms)^## Agent skills\s*\r?\n.*?(?=^##\s|\z)'
  if ([regex]::IsMatch($raw, $pattern)) {
    $updated = [regex]::Replace($raw, $pattern, $block + "`r`n`r`n", 1)
  } else {
    $updated = $raw.TrimEnd() + "`r`n`r`n" + $block + "`r`n"
  }
  # Both this function and Write-AgentsFile own parts of AGENTS.md, so their
  # trailing whitespace has to agree exactly. The replace branch above leaves a
  # blank line at EOF (needed only when another "## " section follows) while
  # Write-AgentsFile normalises to a single newline: without this, each run
  # would undo the other and AGENTS.md would be rewritten twice, forever.
  $updated = $updated.TrimEnd() + "`r`n"
  if ($updated -eq $raw) { return $false }
  if ($DryRun) {
    Write-Host '  [dry] setup Matt Pocock: update AGENTS.md Agent skills block'
    return $true
  }
  # Must go through the tracked writer: a raw Set-Content here would leave the
  # file different from the recorded state, and the very next run would classify
  # the hub's own AGENTS.md as a manual edit and stop updating it.
  Write-HubText -Path $agentsPath -Content $updated
  return $true
}

function Ensure-MattPocockRepoSetup {
  # Non-interactive, idempotent equivalent of the local part of
  # /setup-matt-pocock-skills. Existing files are never overwritten.
  # GitHub labels themselves remain an explicit remote operation.
  param(
    [string]$RepoPath,
    [string]$HubPath,
    [switch]$TriageInstalled,
    [switch]$DryRun
  )
  $skillRoot = Get-MattPocockSkillPath -VendorRoot (Join-Path $HubPath 'vendor\mattpocock-skills') -SkillName 'setup-matt-pocock-skills'
  if (-not $skillRoot) {
    Write-Warning '  Matt Pocock setup skill is unavailable; skipping repository setup.'
    return
  }

  $docsAgents = Join-Path $RepoPath 'docs\agents'
  $adrDir = Join-Path $RepoPath 'docs\adr'
  $origin = Get-RepoOriginUrl -RepoPath $RepoPath
  $issueTemplate = if ($origin -match 'github\.com[:/]') { 'issue-tracker-github.md' } else { 'issue-tracker-local.md' }
  $changed = $false

  foreach ($directory in @($docsAgents, $adrDir)) {
    if (Test-Path -LiteralPath $directory) { continue }
    if ($DryRun) {
      Write-Host "  [dry] setup Matt Pocock: create $directory"
    } else {
      New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $changed = $true
  }

  if (Set-FileFromTemplateIfMissing -Destination (Join-Path $docsAgents 'issue-tracker.md') -Template (Join-Path $skillRoot $issueTemplate) -DryRun:$DryRun) { $changed = $true }
  if (Set-FileFromTemplateIfMissing -Destination (Join-Path $docsAgents 'domain.md') -Template (Join-Path $skillRoot 'domain.md') -DryRun:$DryRun) { $changed = $true }
  if ($TriageInstalled -and (Set-FileFromTemplateIfMissing -Destination (Join-Path $docsAgents 'triage-labels.md') -Template (Join-Path $skillRoot 'triage-labels.md') -DryRun:$DryRun)) { $changed = $true }

  $contextPath = Join-Path $RepoPath 'CONTEXT.md'
  if (-not (Test-Path -LiteralPath $contextPath)) {
    if ($DryRun) {
      Write-Host "  [dry] setup Matt Pocock: write $contextPath"
    } else {
      Write-HubText -Path $contextPath -Content @'
# Domain Context

This document is the project's evolving glossary and domain context. Add terms and decisions through the `domain-modeling` skill when they are resolved.
'@
    }
    $changed = $true
  }
  if (Update-MattPocockAgentSkillsBlock -RepoPath $RepoPath -TriageInstalled:$TriageInstalled -DryRun:$DryRun) { $changed = $true }

  if ($changed) {
    $tracker = if ($issueTemplate -eq 'issue-tracker-github.md') { 'GitHub' } else { 'local Markdown' }
    Write-Host "  configured Matt Pocock skills (tracker: $tracker)"
  } else {
    Write-Host '  Matt Pocock skills already configured'
  }
}

function ConvertTo-TomlBasicString {
  param([string]$Value)
  return $Value.Replace('\', '\\').Replace('"', '\"')
}

function Invoke-NpmGlobalInstall {
  # Capture npm stdout/stderr. Leaving it on the success stream breaks
  # Set-StrictMode callers (Object[] without expected properties).
  param([string]$Package, [switch]$DryRun)
  if ($DryRun) {
    Write-Host "  [dry] npm i -g $Package"
    return $true
  }
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Write-Warning "npm not on PATH; cannot install $Package"
    return $false
  }
  Write-Host "Installing $Package globally..."
  $npmOut = & npm i -g $Package 2>&1
  $npmCode = $LASTEXITCODE
  foreach ($line in @($npmOut)) { Write-Host $line }
  if ($npmCode -ne 0) {
    Write-Warning "npm i -g $Package failed."
    return $false
  }
  return $true
}

function Get-NpmGlobalBin {
  $root = Get-NpmGlobalRoot
  if (-not $root) { return $null }
  return (Split-Path -Parent $root)
}

function Get-CodegraphExe {
  $cmd = Get-Command codegraph -ErrorAction SilentlyContinue
  if ($cmd) { return $cmd.Source }
  $bin = Get-NpmGlobalBin
  if (-not $bin) { return $null }
  foreach ($name in @('codegraph.cmd', 'codegraph.exe', 'codegraph')) {
    $p = Join-Path $bin $name
    if (Test-Path -LiteralPath $p) { return $p }
  }
  return $null
}

function Ensure-CodegraphCli {
  param([switch]$DryRun)
  $exe = Get-CodegraphExe
  if ($exe) { return $exe }
  if (-not (Invoke-NpmGlobalInstall -Package '@colbymchenry/codegraph' -DryRun:$DryRun)) {
    return $null
  }
  $exe = Get-CodegraphExe
  if ($exe) { return $exe }
  Write-Warning 'codegraph was installed but is not on PATH. Open a new terminal or add the npm global bin folder to PATH.'
  return $null
}

function Get-NpmGlobalRoot {
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { return $null }
  $root = (& npm root -g 2>$null | Select-Object -Last 1)
  if ([string]::IsNullOrWhiteSpace($root)) { return $null }
  return $root.Trim()
}

function Find-MongodbMcpEntry {
  param([string]$GlobalRoot)
  if (-not $GlobalRoot) { return $null }
  foreach ($rel in @(
      'mongodb-mcp-server\dist\esm\index.js',
      'mongodb-mcp-server\dist\index.js'
    )) {
    $p = Join-Path $GlobalRoot $rel
    if (Test-Path -LiteralPath $p) { return (Resolve-Path -LiteralPath $p).Path }
  }
  return $null
}

function Resolve-MongodbMcpLaunch {
  # Direct node + global package entry. Do not use `cmd /c npx` on Windows:
  # Cursor/VS Code leaving that chain orphaned accumulates zombie
  # node/cmd/conhost processes and can freeze the IDE.
  #
  # npm writes to the success stream; capture it. Otherwise (with
  # Set-StrictMode) the caller sees an Object[] and `.Node` throws
  # "The property 'Node' cannot be found on this object".
  param([switch]$DryRun)
  $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
  if (-not $nodeCmd) {
    Write-Warning 'node not on PATH; skipping mongodb MCP (no npx fallback — it orphans processes on Windows).'
    return $null
  }
  $nodeExe = $nodeCmd.Source
  $globalRoot = Get-NpmGlobalRoot
  $entry = Find-MongodbMcpEntry -GlobalRoot $globalRoot
  if (-not $entry) {
    if ($DryRun) {
      Write-Host '  [dry] npm i -g mongodb-mcp-server@2'
      return $null
    }
    Write-Host 'Installing mongodb-mcp-server@2 globally (node launch, no npx)...'
    if (-not (Invoke-NpmGlobalInstall -Package 'mongodb-mcp-server@2' -DryRun:$DryRun)) {
      Write-Warning 'npm i -g mongodb-mcp-server@2 failed; skipping mongodb MCP.'
      return $null
    }
    $globalRoot = Get-NpmGlobalRoot
    $entry = Find-MongodbMcpEntry -GlobalRoot $globalRoot
  }
  if (-not $entry) {
    Write-Warning "mongodb-mcp-server entry script not found under $globalRoot"
    return $null
  }
  Write-Host "MongoDB MCP: $nodeExe $entry"
  return [pscustomobject]@{ Node = $nodeExe; Entry = $entry }
}

function Warn-GlobalCursorMongodbDuplicate {
  $path = Join-Path $env:USERPROFILE '.cursor\mcp.json'
  if (-not (Test-Path -LiteralPath $path)) { return }
  try {
    $obj = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    $names = @()
    if ($obj.mcpServers) { $names = @($obj.mcpServers.PSObject.Properties.Name) }
    if ($names -contains 'mongodb') {
      Write-Warning 'Global ~/.cursor/mcp.json also defines mongodb. Hub writes it per NestJS project — disable the global server to avoid a second process in every Cursor window.'
    }
  } catch {
    # ignore unreadable global config
  }
}

function Expand-McpTemplate {
  param([string]$Content, [hashtable]$Vars, [switch]$JsonEscape)
  foreach ($k in $Vars.Keys) {
    $val = $Vars[$k]
    # Converter barras invertidas para barras normais em caminhos Windows (para TOML)
    if ($val -match '^[A-Z]:\\') {
      $val = $val.Replace('\', '/')
    }
    if ($JsonEscape) {
      $encoded = ConvertTo-Json -InputObject ([string]$val) -Compress
      $val = $encoded.Substring(1, $encoded.Length - 2)
    }
    $Content = $Content.Replace("{{$k}}", $val)
  }
  return $Content
}

function Get-JsonProperty {
  param([object]$Object, [string]$Name)
  if (-not $Object) { return $null }
  $prop = $Object.PSObject.Properties[$Name]
  if (-not $prop) { return $null }
  return $prop.Value
}

function Get-NestSwaggerMcpVars {
  # Only when src/main.ts actually sets up Swagger. Live spec URL is used;
  # the MCP needs the API running. toolsMode=dynamic keeps 3 meta-tools.
  param([string]$RepoPath)
  $main = Join-Path $RepoPath 'src\main.ts'
  if (-not (Test-Path $main)) { return $null }
  $text = Get-Content $main -Raw -Encoding UTF8
  if ($text -notmatch 'SwaggerModule') { return $null }

  $port = $null
  $cfgPath = Join-Path $RepoPath 'src\config\.development.json'
  if (Test-Path $cfgPath) {
    try {
      $cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
      $auth = Get-JsonProperty -Object $cfg -Name 'auth'
      $api = Get-JsonProperty -Object $cfg -Name 'api'
      $authPort = Get-JsonProperty -Object $auth -Name 'port'
      $apiPort = Get-JsonProperty -Object $api -Name 'port'
      $rootPort = Get-JsonProperty -Object $cfg -Name 'port'
      if ($RepoPath -match '[\\/][^-\\/]+-auth$' -and $authPort) { $port = [int]$authPort }
      elseif ($apiPort) { $port = [int]$apiPort }
      elseif ($authPort) { $port = [int]$authPort }
      elseif ($rootPort) { $port = [int]$rootPort }
    } catch {
      Write-Warning "Could not parse $cfgPath for OpenAPI MCP port: $_"
    }
  }
  if (-not $port) { $port = 3000 }

  $scheme = 'http'
  if ($text -match 'httpsOptions') { $scheme = 'https' }
  $base = "${scheme}://localhost:$port"

  $specRel = 'docs-json'
  if ($text -match "jsonDocumentUrl:\s*'([^']+)'") {
    $specRel = $Matches[1].TrimStart('/')
  } elseif ($text -match "SwaggerModule\.setup\(\s*'([^']+)'") {
    $specRel = "$($Matches[1])-json"
  }

  return @{
    API_BASE_URL = $base
    OPENAPI_SPEC_PATH = "$base/$specRel"
  }
}

function Get-CatalogMcpCommon {
  param([object]$Catalog)
  if ($Catalog.mcp -and $Catalog.mcp.common) {
    return @($Catalog.mcp.common)
  }
  return @('context7', 'filesystem')
}

function Get-ManagedMcpServerNames {
  param([object]$Catalog, [hashtable]$Families)
  $names = [System.Collections.Generic.List[string]]::new()
  foreach ($s in (Get-CatalogMcpCommon -Catalog $Catalog)) { [void]$names.Add($s) }
  foreach ($family in $Families.Values) {
    foreach ($s in @($family.mcp)) {
      if ($s -and $names -notcontains $s) { [void]$names.Add($s) }
    }
  }
  if ($Catalog.mcp -and $Catalog.mcp.extra) {
    foreach ($extra in @($Catalog.mcp.extra)) {
      foreach ($s in @($extra.servers)) {
        if ($s -and $names -notcontains $s) { [void]$names.Add($s) }
      }
    }
  }
  return @($names)
}

function Get-ProjectMcpServerNames {
  param(
    [string]$ProjectName,
    [object]$FamilyCfg,
    [object]$Catalog
  )
  $names = [System.Collections.Generic.List[string]]::new()
  foreach ($s in (Get-CatalogMcpCommon -Catalog $Catalog)) { [void]$names.Add($s) }
  foreach ($s in @($FamilyCfg.mcp)) {
    if ($s -and $names -notcontains $s) { [void]$names.Add($s) }
  }
  if ($Catalog.mcp -and $Catalog.mcp.extra) {
    foreach ($extra in @($Catalog.mcp.extra)) {
      $matched = $false
      foreach ($pattern in @($extra.match)) {
        if ($ProjectName -like $pattern) { $matched = $true; break }
      }
      if (-not $matched) { continue }
      foreach ($s in @($extra.servers)) {
        if ($s -and $names -notcontains $s) { [void]$names.Add($s) }
      }
    }
  }
  return @($names)
}

function Select-McpServersForIde {
  param($Servers, [string]$Ide, [object]$SkipIdes)
  $out = [ordered]@{}
  foreach ($name in @($Servers.Keys)) {
    $skipFor = @()
    if ($SkipIdes) {
      $skipPropNames = @($SkipIdes.PSObject.Properties | ForEach-Object { $_.Name })
      if ($skipPropNames -contains $name) {
        $skipFor = @($SkipIdes.$name)
      }
    }
    if ($skipFor -contains $Ide) { continue }
    $out[$name] = $Servers[$name]
  }
  return $out
}

function Merge-McpJsonTemplates {
  param([string]$HubPath, [hashtable]$Vars, [string[]]$ServerNames)
  $merged = [ordered]@{}
  foreach ($name in $ServerNames) {
    $path = Join-Path $HubPath "mcp\$name.template.json"
    if (-not (Test-Path $path)) {
      Write-Warning "Missing MCP template: $path"
      continue
    }
    $raw = Get-Content $path -Raw -Encoding UTF8
    $expanded = Expand-McpTemplate -Content $raw -Vars $Vars -JsonEscape
    try {
      $obj = $expanded | ConvertFrom-Json
    } catch {
      throw "Failed to parse MCP template $name.template.json (expanded values omitted to protect credentials)."
    }
    foreach ($prop in $obj.mcpServers.PSObject.Properties) {
      $merged[$prop.Name] = $prop.Value
    }
  }
  return $merged
}

function ConvertTo-OpenCodeMcpServers {
  # OpenCode's schema (https://opencode.ai/docs/mcp-servers) puts servers
  # directly under the top-level "mcp" key (no nested "servers" wrapper).
  param([System.Collections.IDictionary]$Servers)
  $ocServers = [ordered]@{}
  foreach ($name in $Servers.Keys | Sort-Object) {
    $server = $Servers[$name]
    $command = [System.Collections.Generic.List[string]]::new()
    $cmdProp = $server.PSObject.Properties['command']
    if ($cmdProp -and $cmdProp.Value) { [void]$command.Add($cmdProp.Value) }
    $argsProp = $server.PSObject.Properties['args']
    if ($argsProp -and $argsProp.Value) { foreach ($a in $argsProp.Value) { [void]$command.Add($a) } }
    $cfg = [ordered]@{
      type = 'local'
      command = $command.ToArray()
      enabled = $true
    }
    $cwdProp = $server.PSObject.Properties['cwd']
    if ($cwdProp -and $cwdProp.Value) { $cfg.cwd = $cwdProp.Value }
    $envProp = $server.PSObject.Properties['env']
    if ($envProp -and $envProp.Value) {
      $envMap = [ordered]@{}
      foreach ($prop in $envProp.Value.PSObject.Properties) { $envMap[$prop.Name] = $prop.Value }
      if ($envMap.Count -gt 0) { $cfg.environment = $envMap }
    }
    $ocServers[$name] = $cfg
  }
  return $ocServers
}

function Write-OpenCodeConfig {
  param([string]$RepoPath, [System.Collections.Specialized.OrderedDictionary]$McpServers, [string[]]$ManagedServers, [switch]$DryRun)
  Invoke-HubConfig @{path=(Join-Path $RepoPath 'opencode.json'); servers=$McpServers; property='mcp'; managed=$ManagedServers; adopt=[bool]$AdoptLegacyConfigs; dry=[bool]$DryRun}
}

function Write-McpConfigs {
  param(
    [string]$RepoPath,
    [string[]]$Ides,
    [hashtable]$Vars,
    [string[]]$ServerNames,
    [string[]]$ManagedServers,
    [object]$SkipIdes,
    [switch]$DryRun
  )
  # New IDEs: add an entry to Get-IdeRegistry, not a branch here. Server
  # payloads (including mongodb launched via node + global entry, not npx)
  # come from mcp/*.template.json.
  $registry = Get-IdeRegistry
  $allServers = Merge-McpJsonTemplates -HubPath $Vars['HUB'] -Vars $Vars -ServerNames $ServerNames
  if ([string]::IsNullOrWhiteSpace($Vars['CONTEXT7_API_KEY'])) {
    $ctx = $allServers['context7']
    if ($ctx) {
      $ctxArgs = @($ctx.args)
      $idx = [array]::IndexOf($ctxArgs, '--api-key')
      if ($idx -ge 0) {
        $newArgs = [System.Collections.Generic.List[string]]::new()
        $newArgs.AddRange([string[]]$ctxArgs)
        $newArgs.RemoveAt($idx)
        if ($idx -lt $newArgs.Count) { $newArgs.RemoveAt($idx) }
        $ctx.args = $newArgs.ToArray()
      }
    }
  }

  foreach ($ide in $Ides) {
    $ideServers = Select-McpServersForIde -Servers $allServers -Ide $ide -SkipIdes $SkipIdes
    # ConvertTo-Json on OrderedDictionary is an array of {Key,Value} in Windows
    # PowerShell 5.1. Flatten to a plain hashtable before serializing.
    $plain = @{}
    foreach ($k in $ideServers.Keys) { $plain[$k] = $ideServers[$k] }
    # Path and property come from Get-IdeRegistry; only the two genuinely
    # different formats need their own branch. Notes on the non-obvious paths:
    #   OpenCode    - <repo>\opencode.json, "mcp" is a flat server map
    #                 (opencode.ai/docs/config, /docs/mcp-servers)
    #   Antigravity - .agents\mcp_config.json, never a ".antigravity" folder
    #   Claude Code - <repo>\.mcp.json (code.claude.com/docs/en/mcp)
    #   Devin       - .devin\mcp_config.json (older .devin\mcp.json is leftover)
    $entry = $registry[$ide]
    if (-not $entry) { continue }
    if ($entry.Property -eq 'toml') {
      Invoke-HubConfig @{path=(Join-Path $RepoPath ($entry.Mcp -replace '/', '\')); format='toml'; servers=$plain; adopt=[bool]$AdoptLegacyConfigs; dry=[bool]$DryRun}
    }
    elseif ($entry.Property -eq 'mcp') {
      $ocServers = ConvertTo-OpenCodeMcpServers -Servers $plain
      Write-OpenCodeConfig -RepoPath $RepoPath -McpServers $ocServers -ManagedServers $ManagedServers -DryRun:$DryRun
    }
    else {
      Write-McpJsonMerged -Path (Join-Path $RepoPath ($entry.Mcp -replace '/', '\')) -HubServers $plain -ServersProperty $entry.Property -ManagedServerNames $ManagedServers -DryRun:$DryRun
    }
  }
}

function Write-TextFile {
  param([string]$Path, [string]$Content, [switch]$DryRun)
  $dir = Split-Path -Parent $Path
  if ($DryRun) {
    Write-Host "  [dry] write $Path"
    return
  }
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  Set-Content -Path $Path -Value $Content -Encoding UTF8
  Write-Host "  wrote $Path"
}

function Write-McpJsonMerged {
  param([string]$Path, [hashtable]$HubServers, [string]$ServersProperty, [string[]]$ManagedServerNames, [switch]$DryRun)
  Invoke-HubConfig @{path=$Path; servers=$HubServers; property=$ServersProperty; managed=$ManagedServerNames; adopt=[bool]$AdoptLegacyConfigs; dry=[bool]$DryRun}
}

function Write-PointerRules {
  param(
    [string]$RepoPath,
    [string]$HubPath,
    [object]$FamilyCfg,
    [string[]]$Ides,
    [switch]$DryRun
  )
  if ($Ides -notcontains 'Cursor') { return }
  $rulesDir = Join-Path $RepoPath '.cursor\rules'
  if ($FamilyCfg.cursorRule) {
    $src = Join-Path $HubPath "templates\rules\$($FamilyCfg.cursorRule)"
    $dest = Join-Path $rulesDir $FamilyCfg.cursorRule
    if (Test-Path $src) {
      if ($DryRun) { Write-Host "  [dry] rule $($FamilyCfg.cursorRule)" }
      else {
        if (-not (Test-Path $rulesDir)) { New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null }
        Write-HubText -Path $dest -Content (Get-Content $src -Raw -Encoding UTF8) -DryRun:$DryRun
        Write-Host "  rule $($FamilyCfg.cursorRule)"
      }
    }
  }
  foreach ($extra in @($FamilyCfg.extraRules)) {
    if (-not $extra) { continue }
    $src = Join-Path $HubPath "templates\rules\$extra"
    $dest = Join-Path $rulesDir $extra
    if (Test-Path $src) {
      if ($DryRun) { Write-Host "  [dry] rule $extra" }
      else {
        if (-not (Test-Path $rulesDir)) { New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null }
        Write-HubText -Path $dest -Content (Get-Content $src -Raw -Encoding UTF8) -DryRun:$DryRun
        Write-Host "  rule $extra"
      }
    }
  }
}

function Write-SlimStubs {
  param([string]$RepoPath, [string[]]$Ides, [switch]$DryRun)
  $stub = @"
<!-- Point to AGENTS.md - full stack guides live in D:\AGENTS skills (on demand). -->
See **AGENTS.md**. Load stack skills from the linked `D:\AGENTS` instead of duplicating guides here.
"@
  $targets = @()
  if ($Ides -contains 'Cursor') {
    $targets += (Join-Path $RepoPath '.cursorrules')
  }
  if (Test-Path (Join-Path $RepoPath 'GEMINI.md')) {
    # Gemini CLI / Antigravity load GEMINI.md hierarchically from the
    # workspace root (geminicli.com/docs/cli/gemini-md); only slim it if the
    # repo already has one. We do NOT create .gemini\GEMINI.md per project -
    # ~/.gemini is a global, per-user file, not a per-project folder.
    $targets += (Join-Path $RepoPath 'GEMINI.md')
  }
  foreach ($t in $targets) {
    if ($DryRun) { Write-Host "  [dry] stub $(Split-Path $t -Leaf)"; continue }
    $dir = Split-Path -Parent $t
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Write-HubText -Path $t -Content $stub -DryRun:$DryRun
    Write-Host "  stub $(Split-Path $t -Leaf)"
  }
}

function Write-CopilotPointer {
  param(
    [string]$RepoPath,
    [string]$HubPath,
    [string]$Family,
    [string[]]$Ides,
    [switch]$DryRun
  )
  if ($Ides -notcontains 'VSCode') { return }
  $src = Join-Path $HubPath "templates\copilot\$Family.md"
  if (-not (Test-Path $src)) { return }
  $dest = Join-Path $RepoPath '.github\copilot-instructions.md'
  $content = Get-Content $src -Raw -Encoding UTF8
  if ($DryRun) { Write-Host "  [dry] copilot-instructions.md"; return }
  $dir = Split-Path -Parent $dest
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  Write-HubText -Path $dest -Content $content -DryRun:$DryRun
  Write-Host "  wrote .github/copilot-instructions.md"
}

function Write-AntigravityPointer {
  # Antigravity (IDE/CLI) discovers workspace rules under .agents\rules\*.md
  # (see "Where does Antigravity look for Rules and Workflows?", prototypr.io).
  # There is no project-level ".antigravity" folder for rules/skills.
  param(
    [string]$RepoPath,
    [string]$HubPath,
    [string[]]$Ides,
    [switch]$DryRun
  )
  $agDir = Join-Path $RepoPath '.agents\rules'
  if ($Ides -notcontains 'Antigravity') { return }
  $src = Join-Path $HubPath 'templates\antigravity\rules.md'
  if (-not (Test-Path $src)) { return }
  $dest = Join-Path $agDir 'stack-pointer.md'
  $content = Get-Content $src -Raw -Encoding UTF8
  if ($DryRun) { Write-Host "  [dry] .agents/rules/stack-pointer.md"; return }
  if (-not (Test-Path $agDir)) { New-Item -ItemType Directory -Force -Path $agDir | Out-Null }
  Write-HubText -Path $dest -Content $content -DryRun:$DryRun
  Write-Host "  wrote .agents/rules/stack-pointer.md"
}

function Write-KiroSteeringPointer {
  # Kiro steering files live in .kiro\steering\*.md and are always-on by
  # default (kiro.dev/docs/steering). Write a slim pointer so Kiro's native
  # mechanism also carries the "load skills on demand" convention, instead
  # of relying only on AGENTS.md.
  param(
    [string]$RepoPath,
    [string]$ProjectName,
    [string[]]$Ides,
    [switch]$DryRun
  )
  if ($Ides -notcontains 'Kiro') { return }
  $dir = Join-Path $RepoPath '.kiro\steering'
  $dest = Join-Path $dir 'stack-pointer.md'
  $content = @"
---
inclusion: always
---

# $ProjectName

See **AGENTS.md** for stack, commands, and skills. Full stack guides live in
``D:\AGENTS`` skills (junctions under ``.kiro/skills``); load them on demand
instead of duplicating guides here.
"@
  if ($DryRun) { Write-Host "  [dry] .kiro/steering/stack-pointer.md"; return }
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  Write-HubText -Path $dest -Content $content -DryRun:$DryRun
  Write-Host "  wrote .kiro/steering/stack-pointer.md"
}

function Remove-FatAlwaysOnRules {
  param([string]$RepoPath, [switch]$DryRun)
  $fatRules = @(
    (Join-Path $RepoPath '.cursor\rules\nestjs-rules.mdc'),
    (Join-Path $RepoPath '.cursor\rules\cursor.mdc'),
    (Join-Path $RepoPath '.cursor\rules\.cursorrules.mdc')
  )
  # Markers identify candidates; tracked ownership is checked before removal.
  $hubMarkers = @('AgentHub', 'Install-AgentHub', 'nestjs-clean-architecture', 'D:\AGENTS')
  foreach ($fr in $fatRules) {
    if (-not (Test-Path $fr)) { continue }
    $content = Get-Content $fr -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    $isHubGenerated = $false
    foreach ($marker in $hubMarkers) {
      if ($content -and $content.Contains($marker)) { $isHubGenerated = $true; break }
    }
    if (-not $isHubGenerated) {
      Write-Warning ('Skipping removal of {0} - does not appear hub-generated. Remove manually if unneeded.' -f (Split-Path $fr -Leaf))
      continue
    }
    if ($DryRun) { Write-Host "  [dry] remove fat rule $(Split-Path $fr -Leaf)"; continue }
    Invoke-HubConfig @{path=$fr; format='text'; remove=$true; dry=[bool]$DryRun}
    Write-Host "  removed fat rule $(Split-Path $fr -Leaf)"
  }
}

function Remove-LegacyAgentPaths {
  param([string]$RepoPath, [string[]]$Folders, [switch]$DryRun)
  Write-Warning "Legacy folders preserved in $RepoPath. Only tracked AgentHub artifacts are removed by IDE exclusion or uninstall."
}

function Remove-UnusedIdeFolders {
  param([string]$RepoPath, [string[]]$Folders, [switch]$DryRun)
  Write-Warning "Legacy folders preserved in $RepoPath. Only tracked AgentHub artifacts are removed by IDE exclusion or uninstall."
}

function Remove-ExcludedIdeFolders {
  param([string]$RepoPath, [string[]]$ExcludeIdes, [switch]$DryRun)
  foreach ($ide in $ExcludeIdes) {
    Remove-HubIdeArtifacts -RepoPath $RepoPath -Ide $ide -ActiveIdes $detected -DryRun:$DryRun
  }
}

function Link-ProjectSkills {
  param(
    [string]$RepoPath,
    [string]$HubPath,
    [string[]]$SkillNames,
    [string[]]$Ides,
    [switch]$DryRun
  )
  # Roots and the junction-vs-copy decision both come from Get-IdeRegistry, so
  # a new agent needs no change here. Kiro is flagged CopySkills because it does
  # not follow directory junctions when discovering skills.
  $skillRoots = Get-IdeSkillRoots -Ides $Ides
  # Validate each skill once, not once per IDE root: Test-HubSkill parses the
  # SKILL.md, and doing it per root repeated the same work up to 8 times.
  foreach ($skill in $SkillNames) {
    $target = Join-Path $HubPath "skills\$skill"
    if (-not (Test-HubSkill $target)) { throw "Invalid SKILL.md: $target" }
  }
  foreach ($relative in $skillRoots.Keys) {
    $root = Join-Path $RepoPath ($relative -replace '/', '\')
    $forceCopy = [bool]$skillRoots[$relative]
    foreach ($skill in $SkillNames) {
      New-JunctionOrCopy -LinkPath (Join-Path $root $skill) -TargetPath (Join-Path $HubPath "skills\$skill") -DryRun:$DryRun -ForceCopy:$forceCopy
    }
    Remove-StaleProjectSkills -SkillRoot $root -HubPath $HubPath -KeepNames $SkillNames -DryRun:$DryRun
  }
}

function Remove-StaleProjectSkills {
  # Prunes skill junctions the hub linked in a previous run but that are no
  # longer assigned to this project (skill dropped from one of the universal
  # catalog lists or from a family, or renamed). Mirrors how
  # Write-McpJsonMerged prunes stale MCP servers.
  #
  # Only removes an entry when it is hub-managed: either a junction whose
  # target resolves under "<HubPath>\skills\", or a Copy-fallback directory
  # carrying the ".agenthub-managed" marker. A hand-made junction pointing
  # somewhere else, or a real user skill folder, is left untouched.
  param(
    [string]$SkillRoot,
    [string]$HubPath,
    [string[]]$KeepNames,
    [switch]$DryRun
  )
  if (-not (Test-Path $SkillRoot)) { return }
  $hubSkills = (Join-Path $HubPath 'skills').TrimEnd('\')
  $keep = @{}
  foreach ($n in $KeepNames) { $keep[$n] = $true }

  foreach ($entry in Get-ChildItem -LiteralPath $SkillRoot -Directory -Force -ErrorAction SilentlyContinue) {
    if ($keep.ContainsKey($entry.Name)) { continue }

    $isReparse = [bool]($entry.Attributes -band [IO.FileAttributes]::ReparsePoint)
    $isHubManaged = $false
    if ($isReparse) {
      $tgt = $null
      try { $tgt = (Get-Item -LiteralPath $entry.FullName -Force).Target } catch { $tgt = $null }
      if ($tgt) {
        $tgtResolved = $tgt
        try { $tgtResolved = (Resolve-Path -LiteralPath $tgt -ErrorAction Stop).Path } catch { }
        if ($tgtResolved -like "$hubSkills\*") { $isHubManaged = $true }
      }
    } elseif (Test-Path (Join-Path $entry.FullName '.agenthub-managed')) {
      $isHubManaged = $true
    }
    if (-not $isHubManaged) { continue }

    if ($DryRun) { Write-Host "  [dry] prune stale skill $($entry.FullName)"; continue }
    Remove-HubLink -Path $entry.FullName -Root $SkillRoot -HubPath $HubPath
    if (Test-Path $entry.FullName) {
      Write-Warning "Failed to prune stale skill $($entry.FullName)"
    } else {
      Write-Host "  pruned stale skill $($entry.Name)"
    }
  }
}

function Get-AiMemoryExe {
  foreach ($name in @('ai-memory', 'ai-memory.exe')) {
    $cmd = Get-Command $name -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
  }
  # PATH isn't refreshed in an already-open shell right after install; also
  # check the standard native-install locations (Scenario C zip / cargo / ~/bin).
  foreach ($p in @(
      (Join-Path $env:LOCALAPPDATA 'ai-memory\ai-memory.exe'),
      (Join-Path $env:USERPROFILE '.cargo\bin\ai-memory.exe'),
      (Join-Path $env:USERPROFILE 'bin\ai-memory.cmd'),
      (Join-Path $env:USERPROFILE 'bin\ai-memory.ps1')
    )) {
    if ($p -and (Test-Path -LiteralPath $p)) { return $p }
  }
  return $null
}

function Test-AiMemoryEnabled {
  $v = [Environment]::GetEnvironmentVariable('AI_MEMORY_ENABLED', 'Process')
  if ([string]::IsNullOrWhiteSpace($v)) { return $false }
  return ($v.Trim().ToLower() -notin @('0', 'false', 'no', 'off'))
}

function Ensure-AiMemory {
  # Wires akitaonrails/ai-memory (shared cross-agent memory) into each
  # detected agent. Unlike the per-project MCPs this hub writes, ai-memory
  # registers ONE global HTTP MCP entry per agent (~/.claude.json, Cursor
  # config, ...) plus global lifecycle hooks (~/.claude/settings.json,
  # OpenCode plugin); the running server derives the "current project" from
  # the agent's working dir + git root. Requires a running server
  # (docker run ... akitaonrails/ai-memory) and the `ai-memory` CLI on PATH.
  # No-op unless AI_MEMORY_ENABLED is truthy in .env.
  param([string[]]$Ides, [switch]$DryRun)

  if (-not (Test-AiMemoryEnabled)) { return }

  $url = [Environment]::GetEnvironmentVariable('AI_MEMORY_URL', 'Process')
  if ([string]::IsNullOrWhiteSpace($url)) { $url = 'http://127.0.0.1:49374' }
  $url = $url.TrimEnd('/')
  $token = [Environment]::GetEnvironmentVariable('AI_MEMORY_TOKEN', 'Process')

  $exe = Get-AiMemoryExe
  if (-not $exe) {
    Write-Warning "AI_MEMORY_ENABLED is set but the ai-memory CLI is not on PATH. Install it (see README Memoria compartilhada) or unset AI_MEMORY_ENABLED. Skipping ai-memory wiring."
    return
  }

  # Detected-IDE name -> ai-memory --client / --agent slug
  $slugs = @{ Cursor = 'cursor'; Claude = 'claude-code'; OpenCode = 'opencode'; Codex = 'codex'; Devin = 'devin'; Antigravity = 'antigravity-cli' }
  $targets = @($Ides | ForEach-Object { $slugs[$_] } | Where-Object { $_ } | Select-Object -Unique)
  if ($targets.Count -eq 0) {
    Write-Warning "ai-memory: none of the detected IDEs ($($Ides -join ', ')) map to a supported agent. Skipping."
    return
  }

  Write-Host "ai-memory: server $url ; agents: $($targets -join ', ')"
  foreach ($slug in $targets) {
    $mcpArgs  = @('install-mcp', '--client', $slug, '--server-url', "$url/mcp", '--apply')
    $hookArgs = @('install-hooks', '--agent', $slug, '--server-url', $url, '--apply')
    if ($token) {
      $mcpArgs  += @('--auth-token', $token)
      $hookArgs += @('--auth-token', $token)
    }
    if ($DryRun) {
      Write-Host "  [dry] ai-memory install-mcp --client $slug (credentials omitted)"
      Write-Host "  [dry] ai-memory install-hooks --agent $slug (credentials omitted)"
      continue
    }
    & $exe @mcpArgs
    if ($LASTEXITCODE -ne 0) { Write-Warning "  ai-memory install-mcp failed for $slug (exit $LASTEXITCODE)" }
    & $exe @hookArgs
    if ($LASTEXITCODE -ne 0) { Write-Warning "  ai-memory install-hooks failed for $slug (exit $LASTEXITCODE)" }

  }
}

function Get-CodexHome {
  $h = [Environment]::GetEnvironmentVariable('CODEX_HOME', 'Process')
  if ($h -and $h.Trim()) { return $h.Trim() }
  return (Join-Path $HOME '.codex')
}

function Write-AiMemoryProjectConfig {
  # Optional (-WriteAiMemoryToml): pin the ai-memory project slug for a repo.
  # Normally unnecessary - the server derives the project from the git root -
  # only needed for ambiguous checkouts / monorepos / work-vs-personal splits.
  # Never overwrites an existing (possibly hand-edited) file.
  # NOTE: the .ai-memory.toml schema is not fully documented upstream; this
  # writes the minimal `project = "<name>"` form. Verify against your
  # ai-memory version before relying on it.
  param([string]$RepoPath, [string]$ProjectName, [switch]$DryRun)
  if (-not (Test-AiMemoryEnabled)) { return }
  $dest = Join-Path $RepoPath '.ai-memory.toml'
  if (Test-Path $dest) { return }
  if ($DryRun) { Write-Host "  [dry] write .ai-memory.toml (project = `"$ProjectName`")"; return }
  Write-HubText -Path $dest -Content "project = `"$ProjectName`"`r`n" -DryRun:$DryRun
  Write-Host "  wrote .ai-memory.toml"
}

function Get-AgentHubVendors {
  param([string]$HubPath)
  @(
    @{ Name = 'addyosmani/agent-skills'; Path = (Join-Path $HubPath 'vendor\addyosmani-agent-skills') },
    @{ Name = 'mattpocock/skills'; Path = (Join-Path $HubPath 'vendor\mattpocock-skills') },
    @{ Name = 'obra/superpowers'; Path = (Join-Path $HubPath 'vendor\superpowers') },
    @{ Name = 'Leonxlnx/unlazy'; Path = (Join-Path $HubPath 'vendor\unlazy') },
    @{ Name = 'browser-use/browser-harness'; Path = (Join-Path $HubPath 'vendor\browser-harness') },
    @{ Name = 'Drjacky/claude-android-ninja'; Path = (Join-Path $HubPath 'vendor\claude-android-ninja') }
  )
}

function Get-AgentHubVendorRemote {
  param([hashtable]$Vendor)
  $remote = (& git -C $Vendor.Path symbolic-ref --quiet --short refs/remotes/origin/HEAD 2>$null | Select-Object -Last 1)
  if ($LASTEXITCODE -eq 0 -and $remote) { return $remote.Trim() }
  foreach ($candidate in @('origin/main', 'origin/master')) {
    & git -C $Vendor.Path rev-parse --verify --quiet $candidate 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) { return $candidate }
  }
  return $null
}

function Invoke-AgentHubVendorOperation {
  param(
    [string]$HubPath,
    [switch]$Check,
    [switch]$Update
  )
  if ($Check -and $Update) { throw 'Use -CheckVendorUpdates or -UpdateVendors, not both.' }
  $foundChanges = $false
  $hadErrors = $false
  foreach ($vendor in Get-AgentHubVendors -HubPath $HubPath) {
    if (-not (Test-Path (Join-Path $vendor.Path '.git'))) {
      if ($Update) { Write-Warning "Vendor missing; not installing it: $($vendor.Name)" }
      continue
    }

    if ($Check -or $Update) {
      $fetchFailed = $false
      try {
        & git -C $vendor.Path fetch origin --quiet 2>$null
        if ($LASTEXITCODE -ne 0) { $fetchFailed = $true }
      } catch {
        $fetchFailed = $true
      }
      if ($fetchFailed) {
        $hadErrors = $true
        Write-Warning "Could not fetch updates for $($vendor.Name)."
        continue
      }
    }

    $remote = Get-AgentHubVendorRemote -Vendor $vendor
    if (-not $remote) {
      $hadErrors = $true
      Write-Warning "Could not determine origin branch for $($vendor.Name)."
      continue
    }
    $dirty = @(& git -C $vendor.Path status --porcelain 2>$null)
    $commits = @(& git -C $vendor.Path log HEAD..$remote --oneline 2>$null)
    if ($commits.Count -gt 0) { $foundChanges = $true }

    if ($Check) {
      if ($dirty.Count -gt 0) {
        $foundChanges = $true
        Write-Host "[$($vendor.Name)] alterações locais (preservadas):"
        $dirty | ForEach-Object { Write-Host "  $_" }
      }
      if ($commits.Count -gt 0) {
        Write-Host "[$($vendor.Name)] commits novos em ${remote}:"
        $commits | ForEach-Object { Write-Host "  $_" }
        Write-Host "[$($vendor.Name)] resumo:"
        & git -C $vendor.Path diff --stat HEAD..$remote
      }
      continue
    }

    if ($dirty.Count -gt 0) {
      Write-Warning "Skipping $($vendor.Name): local changes detected; review or save them before -UpdateVendors."
      continue
    }
    if ($commits.Count -eq 0) {
      Write-Host "[$($vendor.Name)] already up to date."
      continue
    }
    $before = (& git -C $vendor.Path rev-parse --short HEAD).Trim()
    & git -C $vendor.Path merge --ff-only $remote 2>&1
    if ($LASTEXITCODE -ne 0) {
      Write-Warning "Could not fast-forward $($vendor.Name); no vendor update was applied."
      continue
    }
    $after = (& git -C $vendor.Path rev-parse --short HEAD).Trim()
    Write-Host "[$($vendor.Name)] updated $before -> $after. Review and commit the submodule pointer in the hub."
  }
  if ($Check -and -not $foundChanges -and -not $hadErrors) { Write-Host 'No vendor changes found.' }
  if ($Check -and $hadErrors) { Write-Warning 'Vendor check incomplete; resolve the warnings and run it again.' }
  if ($Update) { Write-Host 'Vendor update operation finished. The hub submodule pointers are not committed automatically.' }
}

# --- main ---
$HubPath = Resolve-HubPath -Path $HubPath
if ($CheckVendorUpdates -or $UpdateVendors) {
  Invoke-AgentHubVendorOperation -HubPath $HubPath -Check:$CheckVendorUpdates -Update:$UpdateVendors
  exit 0
}
& (Get-HubPython) -c "import tomllib" 2>$null
if ($LASTEXITCODE -ne 0) { throw 'AgentHub requires Python 3.11+ (tomllib) for safe TOML validation.' }
$loadedDotEnv = Import-HubDotEnv -HubPath $HubPath
if ($loadedDotEnv) { Write-Host "Loaded $HubPath\.env" }
else { Write-Warning ('No {0}.env - using catalog ides/excludeIdes. Copy .env.example to .env for this machine.' -f $HubPath) }

$catalogPath = Join-Path $HubPath 'catalog\projects.json'
$catalog = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json

# Container of the managed family folders. Overridable per machine so the hub
# is not welded to one drive letter.
$defaultSistemas = if ($env:AGENTHUB_SISTEMAS) { $env:AGENTHUB_SISTEMAS } else { 'D:\SISTEMAS' }
# Family folders whose direct children are managed repos. Comes from
# catalog.roots (Uninstall-AgentHub.ps1 reads the same key); anything else under
# the container is not managed. No hardcoded fallback: a stale copy here silently
# skipped whole product lines.
$defaultProjectRoots = @()
if (($catalog.PSObject.Properties.Name -contains 'roots') -and (@($catalog.roots).Count -gt 0)) {
  $defaultProjectRoots = @($catalog.roots)
} elseif ($ProjectPath.Count -eq 0) {
  throw "catalog/projects.json has no 'roots'. Add them, or target folders explicitly with -ProjectPath."
}

if ($ProjectPath.Count -gt 0) {
  # Explicit targets win outright: the managed roots are not scanned at all.
  if ($Roots.Count -gt 0) {
    Write-Warning '-ProjectPath was given, so -Roots and the catalog roots are ignored.'
  }
  $Roots = @()
} elseif ($Roots.Count -eq 0) {
  $Roots = @($defaultProjectRoots |
    ForEach-Object { Join-Path $defaultSistemas $_ } |
    Where-Object { Test-Path $_ })
} else {
  # Accept the container itself as a convenient root too. Project enumeration
  # scans only one level, so expand it to the managed family folders first.
  $Roots = @($Roots | ForEach-Object {
    $root = $_
    $managedChildren = @($defaultProjectRoots |
      ForEach-Object { Join-Path $root $_ } |
      Where-Object { Test-Path $_ })
    if ($managedChildren.Count -gt 0) { $managedChildren } else { $root }
  })
}
$families = Get-CatalogFamilies -Catalog $catalog

$universalSkillLists = Get-UniversalSkillLists -Catalog $catalog
$commonSkills = @($universalSkillLists['catalog.commonSkills'])
$addyosmaniSkills = @($universalSkillLists['catalog.addyosmaniSkills'])
$mattPocockSkills = @($universalSkillLists['catalog.mattPocockSkills'])
$superpowersSkills = @($universalSkillLists['catalog.superpowersSkills'])

# Guard: verify metadata and body for every native hub skill (not the
# vendor-mirrored ones) has real content before linking anything into
# projects. Junctions faithfully propagate an empty source directory to all
# 24+ repos with no error, so a corrupted/emptied skill here would silently
# strip that skill's instructions everywhere it's used.
$hubSkillsRoot = Join-Path $HubPath 'skills'
$allSkillNamesInUse = [System.Collections.Generic.HashSet[string]]::new()
foreach ($s in @($commonSkills + $addyosmaniSkills + $mattPocockSkills + $superpowersSkills)) {
  [void]$allSkillNamesInUse.Add($s)
}
foreach ($prop in $catalog.families.PSObject.Properties) {
  foreach ($s in @($prop.Value.skills)) { [void]$allSkillNamesInUse.Add($s) }
}
$emptySkills = @()
foreach ($name in $allSkillNamesInUse) {
  $skillDir = Join-Path $hubSkillsRoot $name
  if (-not (Test-Path $skillDir)) { continue } # vendor-mirrored skills not yet linked; Ensure-VendorSkillMirrors handles those
  $item = Get-Item $skillDir -Force
  $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
  if ($isReparse) { continue } # vendor mirror; validated by Test-SkillTargetHasContent when re-linked below
  # Copy fallback of a vendor mirror (junction unavailable): upstream content,
  # not ours to validate or fix with "git checkout" in the hub.
  if (Test-Path (Join-Path $skillDir '.agenthub-managed')) { continue }
  if (-not (Test-HubSkill -Path $skillDir)) { $emptySkills += $name }
}
if ($emptySkills.Count -gt 0) {
  throw "Native hub skill folder(s) have missing or invalid SKILL.md metadata/body: $($emptySkills -join ', '). Refusing to link empty skills into every project. Restore content first, e.g.: git -C `"$HubPath`" checkout -- $(($emptySkills | ForEach-Object { "skills/$_" }) -join ' ')"
}

# Hub skills/ is a flat namespace: skills/<name> can only point at one place.
# When two vendor lists claim the same name, the mirrors run in order and the
# last one silently repoints the junction, so a project ends up with upstream
# content nobody chose. Only one such collision exists across the three
# packages today (test-driven-development, in addyosmani and superpowers) and
# it is selected in neither - which is exactly the kind of thing that stops
# being true without anyone noticing.
Assert-NoSkillNameCollisions -Lists $universalSkillLists
# A vendor skill can be assigned through a family's "skills" list, not only the
# top-level vendor list - frontend-ui-engineering and browser-testing-with-devtools
# live on the angular/minimal families. The mirror still has to resolve those, or
# skills/<name> is never created and every project that wants it fails validation.
# Mirror the union of the declared list and any in-use name the vendor clone
# actually provides; each helper ignores names it can't find.
$addyosmaniMirror = @($addyosmaniSkills) + @(Select-VendorProvidedSkills -HubPath $HubPath -VendorRelativePath 'vendor/addyosmani-agent-skills' -Candidates $allSkillNamesInUse)
$mattPocockMirror = @($mattPocockSkills) + @(Select-VendorProvidedSkills -HubPath $HubPath -VendorRelativePath 'vendor/mattpocock-skills' -Candidates $allSkillNamesInUse -Nested)
$superpowersMirror = @($superpowersSkills) + @(Select-VendorProvidedSkills -HubPath $HubPath -VendorRelativePath 'vendor/superpowers' -Candidates $allSkillNamesInUse)
Ensure-VendorSkillMirrors -HubPath $HubPath -SkillNames @($addyosmaniMirror | Where-Object { $_ } | Select-Object -Unique) -DryRun:$DryRun
Ensure-VendorMattPocockSkillMirrors -HubPath $HubPath -SkillNames @($mattPocockMirror | Where-Object { $_ } | Select-Object -Unique) -DryRun:$DryRun
Ensure-VendorSuperpowersSkillMirrors -HubPath $HubPath -SkillNames @($superpowersMirror | Where-Object { $_ } | Select-Object -Unique) -DryRun:$DryRun
if ($allSkillNamesInUse.Contains('claude-android-ninja')) {
  Ensure-VendorStandaloneSkill `
    -HubPath $HubPath `
    -SkillName 'claude-android-ninja' `
    -VendorRelativePath 'vendor/claude-android-ninja' `
    -Url 'https://github.com/Drjacky/claude-android-ninja.git' `
    -DryRun:$DryRun
}

if ($allSkillNamesInUse.Contains('unlazy')) {
  Ensure-VendorStandaloneSkill `
    -HubPath $HubPath `
    -SkillName 'unlazy' `
    -VendorRelativePath 'vendor/unlazy' `
    -Url 'https://github.com/Leonxlnx/unlazy.git' `
    -DryRun:$DryRun
}

if ($allSkillNamesInUse.Contains('browser-harness')) {
  Ensure-VendorStandaloneSkill `
    -HubPath $HubPath `
    -SkillName 'browser-harness' `
    -VendorRelativePath 'vendor/browser-harness' `
    -Url 'https://github.com/browser-use/browser-harness.git' `
    -DryRun:$DryRun
}
$idePolicy = Resolve-IdePolicy -Catalog $catalog
$allowedIdes = @($idePolicy.Allowed)
$excludeIdes = @($idePolicy.Excluded)
$qoderOptIn = [bool]$catalog.qoderOptIn
$detected = Get-DetectedIdes -Override $Ides -Allowed $allowedIdes -Excluded $excludeIdes -IncludeQoder:($IncludeQoder -or $qoderOptIn) -AllowMissing:$AllowMissing
if ($detected.Count -eq 0) { Write-Warning 'No allowed IDEs detected. Use -Ides, AGENTHUB_IDES in .env, or catalog.ides.' }
if ($catalog.PSObject.Properties['ecc']) {
  foreach ($rel in @((Get-IdeSkillRoots -Ides $detected).Keys)) {
    Sync-EccSkillLinks -HubPath $HubPath -SkillRoot (Join-Path $HubPath $rel) -Catalog $catalog -Names @(Get-EccSkillNames -Catalog $catalog -Maintenance) -DryRun:$DryRun
  }
}
Write-Host "IDE allowlist ($($idePolicy.AllowedSource)): $(if ($allowedIdes.Count) { $allowedIdes -join ', ' } else { 'auto (all detected)' })"
Write-Host "IDE exclude ($($idePolicy.ExcludedSource)): $(if ($excludeIdes.Count) { $excludeIdes -join ', ' } else { '(none)' })"

$context7ApiKey = $env:CONTEXT7_API_KEY
if ([string]::IsNullOrWhiteSpace($context7ApiKey)) {
  Write-Warning 'CONTEXT7_API_KEY not set; context7 MCP will run with public rate limits (get a key at context7.com/dashboard).'
  $context7ApiKey = ''
}
$mongoLaunch = Resolve-MongodbMcpLaunch -DryRun:$DryRun
if ($mongoLaunch -is [System.Array]) {
  $mongoLaunch = $mongoLaunch |
    Where-Object { $_ -and $_.PSObject.Properties['Node'] } |
    Select-Object -Last 1
}
if (-not ($mongoLaunch -and $mongoLaunch.PSObject.Properties['Node'])) {
  $mongoLaunch = $null
}
$codegraphExe = Ensure-CodegraphCli -DryRun:$DryRun
if ($codegraphExe) { Write-Host "codegraph: $codegraphExe" }
if (-not $SkipAiMemory) { Ensure-AiMemory -Ides $detected -DryRun:$DryRun }

Warn-GlobalCursorMongodbDuplicate
$mcpBaseVars = @{
  HUB = $HubPath
  CONTEXT7_API_KEY = $context7ApiKey
  MDB_MCP_CONNECTION_STRING = if ($env:MDB_MCP_CONNECTION_STRING) { $env:MDB_MCP_CONNECTION_STRING } else { 'mongodb://root:password@127.0.0.1:27017/erpclass?authSource=admin' }
}
if ($mongoLaunch) {
  $mcpBaseVars['NODE'] = $mongoLaunch.Node
  $mcpBaseVars['MDB_MCP_ENTRY'] = $mongoLaunch.Entry
}
$managedMcpServers = Get-ManagedMcpServerNames -Catalog $catalog -Families $families
# Retired hub MCP servers: kept here so Write-McpJsonMerged prunes leftover
# entries (written by older script versions) from every project's mcp.json
# even though they're no longer in catalog/projects.json.
#  - memorix: dead placeholder, superseded by ai-memory (global, not per-project)
#  - coreui-docs: renamed to coreui (2026-09-05)
$retiredMcpServers = @('memorix', 'coreui-docs')
$managedMcpServers = @($managedMcpServers) + @($retiredMcpServers | Where-Object { $managedMcpServers -notcontains $_ })
$mcpSkipIdes = $null
if ($catalog.mcp) { $mcpSkipIdes = $catalog.mcp.skipIdes }

Write-Host "Hub: $HubPath"
Write-Host "IDEs: $($detected -join ', ')"
if ($ProjectPath.Count -gt 0) { Write-Host "Targets: $($ProjectPath -join ', ') (catalog roots ignored)" }
else { Write-Host "Roots: $($Roots -join ', ')" }
if ($GlobalSkills -and $detected -contains 'Codex') {
  & (Join-Path $PSScriptRoot 'Sync-Codegraph.ps1') -HubPath $HubPath -Global -AdoptLegacySkills:$AdoptLegacyConfigs -DryRun:$DryRun
  $globalSkillNames = @()
  foreach ($list in $universalSkillLists.Values) { $globalSkillNames += @($list) }
  $globalSkillNames += @(Get-EccSkillNames -Catalog $catalog -Maintenance)
  foreach ($name in @($globalSkillNames | Where-Object { $_ } | Select-Object -Unique)) {
    $target = Join-Path $HubPath "skills/$name"
    if (-not (Test-HubSkill $target)) { throw "Invalid global skill: $name" }
    New-JunctionOrCopy -LinkPath (Join-Path $env:USERPROFILE ".agents/skills/$name") -TargetPath $target -DryRun:$DryRun
  }
}

if ($DryRun) { Write-Host 'DRY RUN - no changes' }

$exclude = @($catalog.excludeProjectNames)
$stats = @{ projects = 0; linked = 0 }
# One bad repository must not abort the rest. A malformed package.json, a
# hand-corrupted mcp.json or an invalid SKILL.md used to throw straight out of
# this loop, leaving the projects before it configured, the ones after it
# untouched, and no summary of what happened - the main way the fleet drifted.
# Failures are now collected per project and reported at the end; the exit code
# reflects them so automation still notices.
$failures = [System.Collections.Generic.List[object]]::new()

# Resolve the exact set of project folders first, so the loop below has one job.
$projectDirs = [System.Collections.Generic.List[object]]::new()
if ($ProjectPath.Count -gt 0) {
  foreach ($raw in $ProjectPath) {
    if (-not (Test-Path -LiteralPath $raw -PathType Container)) {
      throw "-ProjectPath not found (or not a directory): $raw"
    }
    $item = Get-Item -LiteralPath $raw
    if (Test-ProjectDirectory -Path $item.FullName) {
      Write-Host "  target is a repository: $($item.FullName)"
      [void]$projectDirs.Add($item)
    } else {
      # Not a repo itself: treat it as a container of repos.
      $children = @(Get-ChildItem -LiteralPath $item.FullName -Directory -ErrorAction SilentlyContinue)
      Write-Host "  target is a container: $($item.FullName) ($($children.Count) subfolder(s))"
      foreach ($child in $children) { [void]$projectDirs.Add($child) }
    }
  }
} else {
  foreach ($root in $Roots) {
    foreach ($child in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) {
      [void]$projectDirs.Add($child)
    }
  }
}

foreach ($proj in $projectDirs) {
    if ($exclude -contains $proj.Name) { continue }
    try {
    $family = Get-ProjectFamily -Name $proj.Name -Families $families -RepoPath $proj.FullName -Overrides (Get-JsonProperty $catalog 'projectFamilies')
    if (-not (Test-ProjectDirectory -Path $proj.FullName -Family $family)) { continue }

    $cfg = $families[$family]
    Write-Host "`n=== $($proj.Name) [$family] ==="
    $stats.projects++

    $skillNames = @(Get-ProjectSkillNames -Catalog $catalog -FamilyCfg $cfg -Family $family -ProjectName $proj.Name)
    Link-ProjectSkills -RepoPath $proj.FullName -HubPath $HubPath -SkillNames $skillNames -Ides $detected -DryRun:$DryRun
    if ($detected -contains 'Codex') {
      foreach ($old in Get-ChildItem (Join-Path $proj.FullName '.codex/skills') -Directory -ErrorAction SilentlyContinue) {
        Remove-HubLink -Path $old.FullName -Root $proj.FullName -HubPath $HubPath -DryRun:$DryRun
      }
    }
    $hubRefs = Join-Path $HubPath 'references'
    if (Test-Path $hubRefs) {
      New-JunctionOrCopy -LinkPath (Join-Path $proj.FullName 'references') -TargetPath $hubRefs -DryRun:$DryRun
    }
    $mcpVars = $mcpBaseVars.Clone()
    $mcpVars['REPO'] = $proj.FullName
    $mcpServers = Get-ProjectMcpServerNames -ProjectName $proj.Name -FamilyCfg $cfg -Catalog $catalog
    if (-not $mongoLaunch) {
      $mcpServers = @($mcpServers | Where-Object { $_ -ne 'mongodb' })
    }
    if ($mcpServers -contains 'openapi') {
      $oa = Get-NestSwaggerMcpVars -RepoPath $proj.FullName
      if ($oa) {
        $mcpVars['API_BASE_URL'] = $oa.API_BASE_URL
        $mcpVars['OPENAPI_SPEC_PATH'] = $oa.OPENAPI_SPEC_PATH
        Write-Host "  OpenAPI spec: $($oa.OPENAPI_SPEC_PATH)"
      } else {
        $mcpServers = @($mcpServers | Where-Object { $_ -ne 'openapi' })
      }
    }
    Write-Host "  MCP: $($mcpServers -join ', ')"
    Write-McpConfigs -RepoPath $proj.FullName -Ides $detected -Vars $mcpVars -ServerNames $mcpServers -ManagedServers $managedMcpServers -SkipIdes $mcpSkipIdes -DryRun:$DryRun
    Write-PointerRules -RepoPath $proj.FullName -HubPath $HubPath -FamilyCfg $cfg -Ides $detected -DryRun:$DryRun
    Write-CopilotPointer -RepoPath $proj.FullName -HubPath $HubPath -Family $family -Ides $detected -DryRun:$DryRun
    Write-AntigravityPointer -RepoPath $proj.FullName -HubPath $HubPath -Ides $detected -DryRun:$DryRun
    Write-KiroSteeringPointer -RepoPath $proj.FullName -ProjectName $proj.Name -Ides $detected -DryRun:$DryRun
    Remove-FatAlwaysOnRules -RepoPath $proj.FullName -DryRun:$DryRun

    if (-not $SkipCodegraphInit) {
      Ensure-CodegraphInit -RepoPath $proj.FullName -Skills @($cfg.skills) -DryRun:$DryRun
    }

    if ($WriteAiMemoryToml) {
      Write-AiMemoryProjectConfig -RepoPath $proj.FullName -ProjectName $proj.Name -DryRun:$DryRun
    }

    $agentsPath = Join-Path $proj.FullName 'AGENTS.md'
    $writeAgentsHere = $WriteAgents -or $ForceAgents -or (
      ($family -eq 'android') -and -not (Test-Path $agentsPath)
    )
    if ($writeAgentsHere) {
      $tpl = Join-Path $HubPath "templates\agents\$($cfg.agentsTemplate)"
      Write-AgentsFile -RepoPath $proj.FullName -ProjectName $proj.Name -TemplatePath $tpl -Force:$ForceAgents -DryRun:$DryRun
      Write-SlimStubs -RepoPath $proj.FullName -Ides $detected -DryRun:$DryRun
    }

    # Design-system pointer only for UI families that ship the coreui-styling skill.
    if (@($cfg.skills) -contains 'coreui-styling') {
      $designTpl = Join-Path $HubPath 'templates\design-ui.md'
      Write-DesignUiFile -RepoPath $proj.FullName -ProjectName $proj.Name -TemplatePath $designTpl -Force:$ForceAgents -DryRun:$DryRun
    }

    if (-not $SkipMattPocockSetup) {
      Ensure-MattPocockRepoSetup -RepoPath $proj.FullName -HubPath $HubPath -TriageInstalled:($mattPocockSkills -contains 'triage') -DryRun:$DryRun
    }

    if ($RemoveUnusedIdeFolders) {
      $toRemove = @($catalog.unusedIdeFolders)
      Remove-UnusedIdeFolders -RepoPath $proj.FullName -Folders $toRemove -DryRun:$DryRun
    }
    # Always strip hub configs for IDEs in catalog.excludeIdes
    Remove-ExcludedIdeFolders -RepoPath $proj.FullName -ExcludeIdes $excludeIdes -DryRun:$DryRun
    if ($MigrateLegacyPaths) {
      Remove-LegacyAgentPaths -RepoPath $proj.FullName -DryRun:$DryRun
    }
    $stats.linked++
    } catch {
      $failures.Add([pscustomobject]@{ Project = $proj.Name; Path = $proj.FullName; Message = $_.Exception.Message })
      Write-Warning ("  {0}: FAILED, continuing with the other projects - {1}" -f $proj.Name, $_.Exception.Message)
    }
}

Write-Host ("`nDone. Projects configured: {0}; failed: {1}" -f $stats.linked, $failures.Count)
Write-Host "Tip: commit slim AGENTS.md per repo; junctions are local (re-run this script on each machine)."
if ($failures.Count -gt 0) {
  Write-Host ''
  Write-Host 'Projects that failed (fix the cause and re-run; the others are already configured):'
  foreach ($failure in $failures) {
    Write-Host ("  - {0} [{1}]" -f $failure.Project, $failure.Path)
    Write-Host ("      {0}" -f $failure.Message)
  }
  exit 1
}
