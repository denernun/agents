<#
.SYNOPSIS
Remove unchanged AgentHub artifacts, preserving manual content.
.DESCRIPTION
Safe by default: only removes the skill links/copies the hub created.
-Full also removes tracked MCP entries and pointer files. AGENTS.md is always
retained (it carries the project's own "## Local" notes). Global ai-memory hooks
are retained because other projects may use them.

Only hub-owned artifacts are touched: a junction must resolve into the hub, a
copied skill folder must carry .agenthub-managed, and an MCP entry must match
what the hub recorded writing. Manual edits are preserved and reported.

To start over from a blank slate, run with -Full -PruneState and then re-run
Install-AgentHub.ps1.
.EXAMPLE
  # Preview everything the safe mode would remove
  .\Uninstall-AgentHub.ps1 -DryRun
.EXAMPLE
  # Full reset of the managed projects, then reinstall
  .\Uninstall-AgentHub.ps1 -Full -PruneState
  .\Install-AgentHub.ps1 -WriteAgents
.EXAMPLE
  # Clean one repository outside the managed roots
  .\Uninstall-AgentHub.ps1 -ProjectPath C:\dev\meu-api -Full
#>
[CmdletBinding()]
param(
  [string]$HubPath = (Split-Path -Parent $PSScriptRoot),
  [string[]]$Roots = @(),
  # Mirrors Install-AgentHub.ps1: clean specific folders anywhere on disk and
  # ignore the managed roots entirely.
  [string[]]$ProjectPath = @(),
  [switch]$Full,
  [switch]$GlobalSkills,
  [switch]$RemoveLegacyCodexMcp,
  [switch]$GlobalOnly,
  # Drop the hub's ownership records for files it no longer manages. Use with
  # -Full when the point is to start over from a blank slate.
  [switch]$PruneState,
  [switch]$DryRun
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'AgentHub.Common.ps1')
Import-HubFunctions
$cat = Get-Content (Join-Path $HubPath 'catalog/projects.json') -Raw | ConvertFrom-Json
$sistemas = if ($env:AGENTHUB_SISTEMAS) { $env:AGENTHUB_SISTEMAS } else { 'D:\SISTEMAS' }
if ($ProjectPath.Count -gt 0) {
  if ($Roots.Count -gt 0) { Write-Warning '-ProjectPath was given, so -Roots and the catalog roots are ignored.' }
  $Roots = @()
} elseif (-not $Roots.Count) {
  $Roots = @($cat.roots | ForEach-Object { Join-Path $sistemas $_ } | Where-Object { Test-Path $_ })
} else {
  $Roots = @($Roots | ForEach-Object {
    $root = $_
    $children = @($cat.roots | ForEach-Object { Join-Path $root $_ } | Where-Object { Test-Path $_ })
    if ($children.Count) { $children } else { $root }
  } | Select-Object -Unique)
}

# Resolve the projects to clean, mirroring the installer's -ProjectPath rules.
$projects = [System.Collections.Generic.List[object]]::new()
if (-not $GlobalOnly) {
  if ($ProjectPath.Count -gt 0) {
    foreach ($raw in $ProjectPath) {
      if (-not (Test-Path -LiteralPath $raw -PathType Container)) { throw "-ProjectPath not found (or not a directory): $raw" }
      $item = Get-Item -LiteralPath $raw
      if (Test-ProjectDirectory -Path $item.FullName) { [void]$projects.Add($item) }
      else { foreach ($child in @(Get-ChildItem -LiteralPath $item.FullName -Directory -ErrorAction SilentlyContinue)) { [void]$projects.Add($child) } }
    }
  } else {
    foreach ($root in $Roots) {
      foreach ($child in @(Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue)) { [void]$projects.Add($child) }
    }
  }
}

$cleaned = 0
$failures = [System.Collections.Generic.List[object]]::new()
foreach ($project in $projects) {
  if ($cat.excludeProjectNames -contains $project.Name) { continue }
  try {
    if ($Full) {
      # Every IDE the registry knows about, not a list that drifts from it.
      foreach ($ide in @((Get-IdeRegistry).Keys)) {
        Remove-HubIdeArtifacts -RepoPath $project.FullName -Ide $ide -DryRun:$DryRun
      }
      $aiConfig = Join-Path $project.FullName '.ai-memory.toml'
      if (Test-Path $aiConfig) { Invoke-HubConfig @{path=$aiConfig; format='text'; remove=$true; dry=[bool]$DryRun} }
    } else {
      # All known skill roots from the registry, plus the retired .codex/skills
      # that older script versions created. Remove-HubLink handles both
      # junctions and the real copies written for Kiro (.agenthub-managed).
      $skillRoots = @((Get-IdeRegistry).Values | ForEach-Object { $_.Skills }) + @('.codex/skills')
      foreach ($rel in @($skillRoots | Select-Object -Unique)) {
        foreach ($item in Get-ChildItem -LiteralPath (Join-Path $project.FullName $rel) -Directory -Force -ErrorAction SilentlyContinue) {
          Remove-HubLink -Path $item.FullName -Root $project.FullName -HubPath $HubPath -DryRun:$DryRun
        }
      }
    }
    Remove-HubLink -Path (Join-Path $project.FullName 'references') -Root $project.FullName -HubPath $HubPath -DryRun:$DryRun
    $cleaned++
  } catch {
    $failures.Add([pscustomobject]@{ Project = $project.Name; Path = $project.FullName; Message = $_.Exception.Message })
    Write-Warning ("  {0}: FAILED, continuing with the other projects - {1}" -f $project.Name, $_.Exception.Message)
  }
}
if ($GlobalSkills) {
  foreach ($item in Get-ChildItem -LiteralPath (Join-Path $env:USERPROFILE '.agents/skills') -Directory -Force -ErrorAction SilentlyContinue) {
    Remove-HubLink -Path $item.FullName -Root $env:USERPROFILE -HubPath $HubPath -DryRun:$DryRun
  }
}
if ($RemoveLegacyCodexMcp) {
  $codexRoot = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $env:USERPROFILE '.codex' }
  $path = Join-Path $codexRoot 'config.toml'
  if (Test-Path $path) { Invoke-HubConfig @{path=$path; format='toml'; legacy_global=$true; remove=$true; dry=[bool]$DryRun} }
}

if ($PruneState) {
  # Ownership records whose file is gone are dead weight; dropping them makes a
  # following install behave exactly like a first install. Records for files
  # that still exist are kept, so this never silently un-manages live config.
  $stateRoot = Join-Path $HubPath '.agenthub-state'
  $pruned = 0
  $kept = 0
  foreach ($stateFile in @(Get-ChildItem -LiteralPath $stateRoot -Filter '*.json' -File -ErrorAction SilentlyContinue)) {
    $tracked = $null
    try { $tracked = (Get-Content -LiteralPath $stateFile.FullName -Raw | ConvertFrom-Json).path } catch { $tracked = $null }
    if ($tracked -and (Test-Path -LiteralPath $tracked)) { $kept++; continue }
    if ($DryRun) { $pruned++; continue }
    Remove-Item -LiteralPath $stateFile.FullName -Force
    $pruned++
  }
  Write-Host ("State records: {0} pruned (file gone), {1} kept (file still present){2}" -f $pruned, $kept, $(if ($DryRun) { ' [dry]' } else { '' }))
}

Write-Host ("`nDone. Projects cleaned: {0}; failed: {1}" -f $cleaned, $failures.Count)
Write-Host 'Preserved on purpose: manual edits, AGENTS.md, .agenthub-state/backups and the global ai-memory integration.'
if (-not $Full) { Write-Host 'This was the safe mode (skill links only). Use -Full to also remove tracked MCP entries and pointer files.' }
if ($failures.Count -gt 0) {
  Write-Host ''
  Write-Host 'Projects that failed:'
  foreach ($failure in $failures) {
    Write-Host ("  - {0} [{1}]" -f $failure.Project, $failure.Path)
    Write-Host ("      {0}" -f $failure.Message)
  }
  exit 1
}
