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
$profilePath = [string]$PROFILE
$profileText = if (Test-Path -LiteralPath $profilePath) { Get-Content -LiteralPath $profilePath -Raw } else { '' }
$guardIndex = $profileText.IndexOf('[Console]::IsInputRedirected', [StringComparison]::OrdinalIgnoreCase)
$iconsIndex = $profileText.IndexOf('Import-Module -Name Terminal-Icons', [StringComparison]::OrdinalIgnoreCase)
$profileGuardOk = ($iconsIndex -lt 0) -or ($guardIndex -ge 0 -and $guardIndex -lt $iconsIndex)
if (-not $profileGuardOk) {
  Write-Warning "PowerShell profile does not guard Terminal-Icons before import: $profilePath"
} else {
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

if (-not $mcpOk -or -not $serverOk -or -not $hookOk -or -not $profileGuardOk) { exit 1 }
Write-Output 'Cursor/Orca ai-memory checks: PASS. The hook preflight did not send an event to the memory server.'
