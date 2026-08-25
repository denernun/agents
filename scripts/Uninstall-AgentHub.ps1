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

function Remove-HubServersFromMcpJson {
  # Surgically removes only hub-managed servers from an MCP JSON config file,
  # preserving user-added servers and all other top-level properties.
  # Deletes the file only if no servers remain and no other properties exist.
  param(
    [string]$Path,
    [string]$ServersProperty,  # 'mcpServers' or 'servers'
    [string[]]$HubServerNames,
    [switch]$DryRun
  )
  if (-not (Test-Path $Path)) { return }
  $content = Get-Content $Path -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
  if (-not $content) { return }

  try {
    $obj = $content | ConvertFrom-Json
  } catch {
    Write-Warning "Cannot parse $Path as JSON — skipping (remove manually if unneeded)."
    return
  }

  $servers = $obj.$ServersProperty
  if (-not $servers) {
    # File has no servers property — nothing hub-managed here
    return
  }

  $remaining = [ordered]@{}
  $removedAny = $false
  foreach ($prop in $servers.PSObject.Properties) {
    if ($HubServerNames -contains $prop.Name) {
      $removedAny = $true
    } else {
      $remaining[$prop.Name] = $prop.Value
    }
  }

  if (-not $removedAny) { return }

  # Check if anything meaningful remains
  $otherProps = @($obj.PSObject.Properties | Where-Object { $_.Name -ne $ServersProperty })
  $hasUserServers = ($remaining.Count -gt 0)
  $hasOtherContent = ($otherProps.Count -gt 0)

  if (-not $hasUserServers -and -not $hasOtherContent) {
    # Nothing left — remove the file entirely
    if ($DryRun) { Write-Host "[dry] remove $Path (no user content remains)"; return }
    Remove-Item $Path -Force
    Write-Host "removed $Path (no user content remains)"
  } else {
    # Rewrite with only user servers + preserved properties
    if ($DryRun) { Write-Host "[dry] strip hub servers from $Path"; return }
    $output = [ordered]@{}
    foreach ($p in $otherProps) { $output[$p.Name] = $p.Value }
    if ($hasUserServers) { $output[$ServersProperty] = $remaining }
    $json = $output | ConvertTo-Json -Depth 10
    Set-Content -Path $Path -Value $json -Encoding UTF8
    Write-Host "stripped hub servers from $Path (user servers preserved)"
  }
}

if (-not $HubPath) {
  $scriptParent = Split-Path -Parent $PSScriptRoot
  if (Test-Path (Join-Path $scriptParent 'catalog\projects.json')) {
    $HubPath = $scriptParent
  } elseif (Test-Path 'D:\AGENTS\catalog\projects.json') {
    $HubPath = 'D:\AGENTS'
  } else {
    $HubPath = 'D:\AGENTS'
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

# Build the list of hub-managed MCP server names from catalog (for surgical MCP removal)
$hubMcpServerNames = @()
if ($Full) {
  $catalogPath2 = Join-Path $HubPath 'catalog\projects.json'
  if (Test-Path $catalogPath2) {
    $cat = Get-Content $catalogPath2 -Raw -Encoding UTF8 | ConvertFrom-Json
    $names = [System.Collections.Generic.List[string]]::new()
    if ($cat.mcp -and $cat.mcp.common) { foreach ($s in @($cat.mcp.common)) { if ($s) { [void]$names.Add($s) } } }
    if ($cat.families) {
      foreach ($prop in $cat.families.PSObject.Properties) {
        $fam = $prop.Value
        if ($fam.mcp) { foreach ($s in @($fam.mcp)) { if ($s -and $names -notcontains $s) { [void]$names.Add($s) } } }
      }
    }
    if ($cat.mcp -and $cat.mcp.extra) {
      foreach ($extra in @($cat.mcp.extra)) { foreach ($s in @($extra.servers)) { if ($s -and $names -notcontains $s) { [void]$names.Add($s) } } }
    }
    $hubMcpServerNames = @($names)
  }
  if ($hubMcpServerNames.Count -eq 0) {
    # Hardcoded fallback covering known hub servers
    $hubMcpServerNames = @('context7', 'filesystem', 'memorix', 'mongodb', 'openapi', 'playwright')
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
  '.devin\skills',
  '.github\skills'
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
      # MCP configs — surgically remove only hub-managed servers, preserving user additions
      Remove-HubServersFromMcpJson -Path (Join-Path $projPath '.cursor\mcp.json') -ServersProperty 'mcpServers' -HubServerNames $hubMcpServerNames -DryRun:$DryRun
      Remove-HubServersFromMcpJson -Path (Join-Path $projPath '.vscode\mcp.json') -ServersProperty 'servers' -HubServerNames $hubMcpServerNames -DryRun:$DryRun
      Remove-HubServersFromMcpJson -Path (Join-Path $projPath '.kiro\settings\mcp.json') -ServersProperty 'mcpServers' -HubServerNames $hubMcpServerNames -DryRun:$DryRun
      Remove-HubServersFromMcpJson -Path (Join-Path $projPath '.qoder\mcp.json') -ServersProperty 'mcpServers' -HubServerNames $hubMcpServerNames -DryRun:$DryRun
      Remove-HubServersFromMcpJson -Path (Join-Path $projPath '.agents\mcp_config.json') -ServersProperty 'mcpServers' -HubServerNames $hubMcpServerNames -DryRun:$DryRun
      Remove-HubServersFromMcpJson -Path (Join-Path $projPath '.mcp.json') -ServersProperty 'mcpServers' -HubServerNames $hubMcpServerNames -DryRun:$DryRun
      Remove-HubServersFromMcpJson -Path (Join-Path $projPath '.devin\mcp_config.json') -ServersProperty 'mcpServers' -HubServerNames $hubMcpServerNames -DryRun:$DryRun

      # Rules / pointers / stubs - only remove files this hub is known to
      # write, never the whole .cursor\rules directory (it may contain
      # rules the user added by hand or via the Cursor marketplace).
      foreach ($rule in @('stack-pointer-nestjs.mdc', 'stack-pointer-angular.mdc', 'stack-pointer-delphi.mdc', 'stack-pointer-android.mdc', 'decorator-placement.mdc')) {
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
  Write-Host "`nNote: AGENTS.md and opencode.json were left in place (they may contain project-specific / hand-edited content)."
  Write-Host "Remove them manually per repo if you no longer want AgentHub-managed files there."
}
