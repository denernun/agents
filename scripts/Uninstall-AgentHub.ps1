<#
.SYNOPSIS
Remove unchanged AgentHub artifacts, preserving manual content.
.DESCRIPTION
-Full removes tracked MCPs and pointers. AGENTS.md is retained.
Global ai-memory hooks are retained because other projects may use them.
#>
[CmdletBinding()]
param(
  [string]$HubPath = (Split-Path -Parent $PSScriptRoot),
  [string[]]$Roots = @(),
  [switch]$Full,
  [switch]$GlobalSkills,
  [switch]$RemoveLegacyCodexMcp,
  [switch]$GlobalOnly,
  [switch]$DryRun
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'AgentHub.Common.ps1')
$cat = Get-Content (Join-Path $HubPath 'catalog/projects.json') -Raw | ConvertFrom-Json
if (-not $Roots.Count) { $Roots = @($cat.roots | ForEach-Object { Join-Path 'D:/SISTEMAS' $_ } | Where-Object { Test-Path $_ }) }
$Roots = @($Roots | ForEach-Object {
  $root = $_
  $children = @($cat.roots | ForEach-Object { Join-Path $root $_ } | Where-Object { Test-Path $_ })
  if ($children.Count) { $children } else { $root }
} | Select-Object -Unique)
foreach ($root in $(if ($GlobalOnly) { @() } else { $Roots })) {
  foreach ($project in Get-ChildItem -LiteralPath $root -Directory) {
    if ($cat.excludeProjectNames -contains $project.Name) { continue }
    if ($Full) {
      foreach ($ide in @('Cursor','Claude','Codex','Antigravity','OpenCode','VSCode','Kiro','Devin','Qoder')) {
        Remove-HubIdeArtifacts -RepoPath $project.FullName -Ide $ide -DryRun:$DryRun
      }
      $aiConfig = Join-Path $project.FullName '.ai-memory.toml'
      if (Test-Path $aiConfig) { Invoke-HubConfig @{path=$aiConfig; format='text'; remove=$true; dry=[bool]$DryRun} }
    } else {
      foreach ($rel in @('.cursor/skills','.claude/skills','.codex/skills','.agents/skills','.opencode/skills','.github/skills','.kiro/skills','.devin/skills')) {
        foreach ($item in Get-ChildItem -LiteralPath (Join-Path $project.FullName $rel) -Directory -Force -ErrorAction SilentlyContinue) {
          Remove-HubLink -Path $item.FullName -Root $project.FullName -HubPath $HubPath -DryRun:$DryRun
        }
      }
    }
    Remove-HubLink -Path (Join-Path $project.FullName 'references') -Root $project.FullName -HubPath $HubPath -DryRun:$DryRun
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
Write-Host 'Done. Manual content, AGENTS.md, backups and global ai-memory integration preserved.'
