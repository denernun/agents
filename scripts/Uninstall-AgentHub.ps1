<#
.SYNOPSIS
  Removes junctions and generated files created by Install-AgentHub.ps1
  (does not delete the hub itself).

.DESCRIPTION
  By default only removes skill junctions (safe, reversible: re-run Install
  to relink). Pass -Full to also remove generated MCP configs, AGENTS.md,
  slim stubs, Cursor rules, and Copilot/Antigravity/Kiro pointers - i.e. a
  complete, symmetric uninstall of everything Install-AgentHub.ps1 writes.

.EXAMPLE
  .\Uninstall-AgentHub.ps1 -DryRun

.EXAMPLE
  .\Uninstall-AgentHub.ps1 -Full
#>
[CmdletBinding()]
param(
  [string]$HubPath = '',
  [string[]]$Roots = @(),
  [switch]$Full,
  [switch]$DryRun
)

function Remove-PathIfExists {
  param([string]$Path, [switch]$DryRun)
  if (-not (Test-Path $Path)) { return }
  if ($DryRun) { Write-Host "[dry] remove $Path"; return }
  Remove-Item $Path -Recurse -Force
  Write-Host "removed $Path"
}

if (-not $HubPath) {
  $scriptParent = Split-Path -Parent $PSScriptRoot
  if (Test-Path (Join-Path $scriptParent 'catalog\projects.json')) {
    $HubPath = $scriptParent
  } elseif (Test-Path 'D:\AGENTS\catalog\projects.json') {
    $HubPath = 'D:\AGENTS'
  } else {
    $HubPath = 'D:\IA\agents'
  }
}

$defaultSistemas = 'D:\SISTEMAS'
if ($Roots.Count -eq 0) {
  $catalogPath = Join-Path $HubPath 'catalog\projects.json'
  if (Test-Path $catalogPath) {
    $catalog = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json
    if ($catalog.roots -and $catalog.roots.Count -gt 0) {
      $Roots = @($catalog.roots | ForEach-Object { Join-Path $defaultSistemas $_ } | Where-Object { Test-Path $_ })
    }
  }
  if ($Roots.Count -eq 0) {
    $Roots = @(
      (Join-Path $defaultSistemas 'ERPCLASS'),
      (Join-Path $defaultSistemas 'NFECLASS'),
      (Join-Path $defaultSistemas 'MOBICLASS')
    ) | Where-Object { Test-Path $_ }
  }
}

# Skill junctions (matches Link-ProjectSkills targets in Install-AgentHub.ps1)
$skillDirs = @(
  '.cursor\skills',
  '.agents\skills',
  '.kiro\skills',
  '.opencode\skills',
  '.claude\skills',
  '.codex\skills',
  '.devin\skills'
)
foreach ($root in $Roots) {
  if (-not (Test-Path $root)) { continue }
  Get-ChildItem $root -Directory | ForEach-Object {
    $projPath = $_.FullName
    foreach ($rel in $skillDirs) {
      $skillsRoot = Join-Path $projPath $rel
      if (-not (Test-Path $skillsRoot)) { continue }
      Get-ChildItem $skillsRoot -Force -ErrorAction SilentlyContinue | ForEach-Object {
        $item = $_
        $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
        if (-not $isReparse) { return }
        if ($DryRun) {
          Write-Host "[dry] rmdir $($item.FullName)"
        } else {
          cmd /c "rmdir `"$($item.FullName)`"" | Out-Null
          Write-Host "removed junction $($item.FullName)"
        }
      }
    }

    $refPath = Join-Path $projPath 'references'
    if (Test-Path $refPath) {
      $item = Get-Item $refPath -Force
      $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
      if ($isReparse) {
        if ($DryRun) { Write-Host "[dry] rmdir $refPath" }
        else {
          cmd /c "rmdir `"$refPath`"" | Out-Null
          Write-Host "removed junction $refPath"
        }
      }
    }

    if ($Full) {
      # MCP configs (matches Write-McpConfigs targets in Install-AgentHub.ps1)
      Remove-PathIfExists -Path (Join-Path $projPath '.cursor\mcp.json') -DryRun:$DryRun
      Remove-PathIfExists -Path (Join-Path $projPath '.vscode\mcp.json') -DryRun:$DryRun
      Remove-PathIfExists -Path (Join-Path $projPath '.kiro\settings\mcp.json') -DryRun:$DryRun
      Remove-PathIfExists -Path (Join-Path $projPath '.qoder\mcp.json') -DryRun:$DryRun
      Remove-PathIfExists -Path (Join-Path $projPath '.agents\mcp_config.json') -DryRun:$DryRun
      Remove-PathIfExists -Path (Join-Path $projPath '.mcp.json') -DryRun:$DryRun
      Remove-PathIfExists -Path (Join-Path $projPath '.devin\mcp_config.json') -DryRun:$DryRun

      # Rules / pointers / stubs - only remove files this hub is known to
      # write, never the whole .cursor\rules directory (it may contain
      # rules the user added by hand or via the Cursor marketplace).
      foreach ($rule in @('stack-pointer-nestjs.mdc', 'stack-pointer-angular.mdc', 'stack-pointer-delphi.mdc', 'decorator-placement.mdc')) {
        Remove-PathIfExists -Path (Join-Path $projPath ".cursor\rules\$rule") -DryRun:$DryRun
      }
      Remove-PathIfExists -Path (Join-Path $projPath '.cursorrules') -DryRun:$DryRun
      Remove-PathIfExists -Path (Join-Path $projPath '.github\copilot-instructions.md') -DryRun:$DryRun
      Remove-PathIfExists -Path (Join-Path $projPath '.agents\rules\stack-pointer.md') -DryRun:$DryRun
      Remove-PathIfExists -Path (Join-Path $projPath '.kiro\steering\stack-pointer.md') -DryRun:$DryRun

      # AGENTS.md is intentionally NOT removed by default (it may contain a
      # hand-edited "## Local" section). Remove manually if truly needed.
    }
  }
}

if ($Full) {
  Write-Host "`nNote: AGENTS.md, opencode.json and .codex\config.toml were left in place (they may contain project-specific / hand-edited content)."
  Write-Host "Remove them manually per repo if you no longer want AgentHub-managed files there."
}
