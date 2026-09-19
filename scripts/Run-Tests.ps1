<#
.SYNOPSIS
Run the whole AgentHub test suite and report one verdict.
.DESCRIPTION
The suite is split across two runtimes, so there was no single command to trust:
pytest covers the config writer, the agent templates and the skill stocktake;
the PowerShell scripts cover installer behaviour end to end against throwaway
fixtures under .audit-output.

Exits non-zero if any part fails, so this is the command to run before commit.
.EXAMPLE
  .\Run-Tests.ps1
.EXAMPLE
  # Skip the slower PowerShell integration fixtures
  .\Run-Tests.ps1 -PythonOnly
#>
[CmdletBinding()]
param(
  [switch]$PythonOnly,
  [switch]$PowerShellOnly
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
. (Join-Path $PSScriptRoot 'AgentHub.Common.ps1')

$hub = Split-Path -Parent $PSScriptRoot
$results = [System.Collections.Generic.List[object]]::new()

function Add-Result {
  param([string]$Name, [bool]$Ok, [string]$Detail = '')
  $results.Add([pscustomobject]@{ Name = $Name; Ok = $Ok; Detail = $Detail })
  Write-Host ("  {0} {1}{2}" -f $(if ($Ok) { '[ok]  ' } else { '[FAIL]' }), $Name, $(if ($Detail) { " - $Detail" } else { '' }))
}

if (-not $PowerShellOnly) {
  Write-Host "`nPython (pytest)"
  $python = Get-HubPython
  $out = & $python -m pytest (Join-Path $PSScriptRoot 'tests') -q 2>&1
  $ok = $LASTEXITCODE -eq 0
  $summary = @($out | Where-Object { $_ -match 'passed|failed|error' } | Select-Object -Last 1)
  Add-Result -Name 'pytest scripts/tests' -Ok $ok -Detail ([string]$summary).Trim()
  if (-not $ok) { $out | ForEach-Object { Write-Host "      $_" } }
}

if (-not $PythonOnly) {
  Write-Host "`nPowerShell integration"
  foreach ($script in @('tests\Test-Integration.ps1', 'tests\Test-Ecc.ps1')) {
    $path = Join-Path $PSScriptRoot $script
    if (-not (Test-Path $path)) { Add-Result -Name $script -Ok $false -Detail 'not found'; continue }
    $log = Join-Path $hub ('.audit-output\run-tests-' + (Split-Path $script -Leaf) + '.log')
    & $path *> $log
    $ok = $LASTEXITCODE -eq 0
    $tail = @(Get-Content -LiteralPath $log -ErrorAction SilentlyContinue | Where-Object { $_ -match 'checks passed|Assert|Exception' } | Select-Object -Last 1)
    Add-Result -Name $script -Ok $ok -Detail ([string]$tail).Trim()
    if (-not $ok) { Write-Host "      full log: $log" }
  }
}

$failed = @($results | Where-Object { -not $_.Ok })
Write-Host ("`n{0} check(s), {1} failed" -f $results.Count, $failed.Count)
if ($failed.Count -gt 0) { exit 1 }
Write-Host 'Suite green.'
exit 0
