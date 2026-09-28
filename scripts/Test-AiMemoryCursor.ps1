<# Read-only smoke test for the native Cursor/Orca ai-memory hook path. #>
[CmdletBinding()]
param([string]$HubPath = (Split-Path -Parent $PSScriptRoot))

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'AgentHub.Common.ps1')
Import-HubFunctions

$exe = Get-AiMemoryExe
if (-not $exe) { throw 'ai-memory CLI was not found.' }
$version = (& $exe --version 2>$null | Out-String).Trim()
Write-Output "ai-memory CLI: $version ($exe)"

$mcpPath = Join-Path $HOME '.cursor\mcp.json'
$mcpOk = $false
if (Test-Path -LiteralPath $mcpPath) {
  try {
    $mcp = Get-Content -LiteralPath $mcpPath -Raw -Encoding UTF8 | ConvertFrom-Json
    $mcpOk = ($mcp.mcpServers.'ai-memory'.url -match '/mcp$')
  } catch { $mcpOk = $false }
}
if (-not $mcpOk) { Write-Warning "Cursor's global ai-memory MCP entry is missing/invalid: $mcpPath" }

$serverStatus = & $exe status 2>&1
$serverOk = ($LASTEXITCODE -eq 0 -and @($serverStatus | Where-Object { $_ -match '^  server:' }).Count -gt 0)
if ($serverOk) {
  $serverLine = [string]($serverStatus | Where-Object { $_ -match '^  server:' } | Select-Object -First 1)
  Write-Output "ai-memory server: $($serverLine.Trim())"
} else {
  Write-Warning 'ai-memory server status check failed; the Cursor hook can launch, but cannot capture until the server is reachable.'
}

$hookOk = Test-AiMemoryCursorPreToolUse -Exe $exe

# Cursor also imports Claude Code's user hooks and drops their separate `args`
# array. A bare `ai-memory install-hooks` / `upgrade` run outside the hub
# restores that shape; flag it here instead of discovering it inside Orca.
$claudeDir = if ($env:CLAUDE_CONFIG_DIR) { $env:CLAUDE_CONFIG_DIR } else { Join-Path $HOME '.claude' }
$claudeSettingsPath = Join-Path $claudeDir 'settings.json'
$claudeHooksOk = $true
$claudeCommands = @()
if (Test-Path -LiteralPath $claudeSettingsPath) {
  $claudeSettings = Get-Content -LiteralPath $claudeSettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json
  if ($claudeSettings.PSObject.Properties['hooks']) {
    foreach ($eventProperty in $claudeSettings.hooks.PSObject.Properties) {
      foreach ($group in @($eventProperty.Value)) {
        foreach ($hook in @($group.hooks)) {
          if ([string]$hook.command -notmatch 'ai-memory') { continue }
          $claudeCommands += [string]$hook.command
          if ($hook.PSObject.Properties['args'] -or [string]$hook.command -notmatch '^cmd(?:\.exe)?\s+/d\s+/s\s+/c\s') {
            $claudeHooksOk = $false
          }
        }
      }
    }
  }
}
if (-not $claudeHooksOk) {
  Write-Warning "Claude ai-memory hooks in $claudeSettingsPath use a separate args array or no cmd.exe wrapper; Cursor will run them without arguments. Re-run Install-AgentHub.ps1."
} elseif ($claudeCommands.Count) {
  Write-Output "Claude ai-memory hooks (imported by Cursor): OK ($($claudeCommands.Count))"
}

# Orca runs agents in worktrees (~/orca/workspaces/<repo>/<branch>). Without
# repo-root the hooks name the project after the worktree folder, splitting memory.
$cursorHooksText = Get-Content -LiteralPath (Join-Path $HOME '.cursor\hooks.json') -Raw -ErrorAction SilentlyContinue
$strategyOk = [bool]($cursorHooksText -match 'repo-root') -and (-not $claudeCommands.Count -or @($claudeCommands | Where-Object { $_ -notmatch 'repo-root' }).Count -eq 0)
if ($strategyOk) {
  Write-Output 'ai-memory project strategy: repo-root (worktrees share the main repo project)'
} else {
  Write-Warning 'ai-memory hooks do not bake --project-strategy repo-root; Orca worktrees will be recorded under their folder name. Re-run Install-AgentHub.ps1.'
}

# Resolve the project from inside a real Orca worktree, when one exists.
$orcaRoot = Join-Path $HOME 'orca\workspaces'
$worktree = Get-ChildItem -LiteralPath $orcaRoot -Directory -ErrorAction SilentlyContinue |
  ForEach-Object { Get-ChildItem -LiteralPath $_.FullName -Directory -ErrorAction SilentlyContinue } |
  Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName '.git') } | Select-Object -First 1
if ($worktree) {
  $mainRoot = (& git -C $worktree.FullName rev-parse --path-format=absolute --git-common-dir 2>$null)
  if ($mainRoot) { $mainRoot = Split-Path -Parent $mainRoot }
  Write-Output "Orca worktree sample: $($worktree.FullName)"
  Write-Output "  main repo root: $mainRoot (repo-root project: $(if ($mainRoot) { Split-Path -Leaf $mainRoot } else { '?' }); basename would be: $($worktree.Name))"
} else {
  Write-Output "No Orca worktree found under $orcaRoot; worktree project resolution not sampled."
}

$profilePath = Get-PwshProfilePath
$profileGuardOk = Test-PowerShellProfileGuard -ProfilePath $profilePath
if ($profileGuardOk) {
  $pwsh = Get-Command pwsh -ErrorAction SilentlyContinue
  if (-not $pwsh) {
    $profileGuardOk = $false
    Write-Warning 'pwsh was not found; unable to smoke-test the PowerShell profile.'
  } else {
    $probeCode = 'Write-Output "AI_MEMORY_PROFILE_PROBE"; Write-Output ("stdin_redirected=" + [Console]::IsInputRedirected)'
    $probe = '' | & $pwsh.Source -NoLogo -Command $probeCode 2>&1
    $probeText = $probe -join "`n"
    if ($LASTEXITCODE -ne 0 -or $probeText -notmatch 'AI_MEMORY_PROFILE_PROBE' -or
        $probeText -notmatch 'stdin_redirected=True' -or $probeText -match 'Import-Clixml|Root element is missing|invalid XmlNodeType') {
      $profileGuardOk = $false
      Write-Warning 'Redirected PowerShell startup failed its profile/Terminal-Icons smoke test.'
      Write-Output $probeText
    } else {
      Write-Output "PowerShell profile guard: OK ($profilePath)"
    }
  }
}

if (-not $mcpOk -or -not $serverOk -or -not $hookOk -or -not $claudeHooksOk -or -not $strategyOk -or -not $profileGuardOk) { exit 1 }
Write-Output 'Cursor/Orca ai-memory checks: PASS. The hook preflight did not send an event to the memory server.'
