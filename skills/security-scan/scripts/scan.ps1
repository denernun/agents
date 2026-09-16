[CmdletBinding()]
param([Parameter(Mandatory)][string]$Path, [switch]$DryRun)
$ErrorActionPreference = 'Stop'
$resolved = (Resolve-Path -LiteralPath $Path).Path
if (-not (Test-Path -LiteralPath $resolved -PathType Container)) { throw 'Scan path must be a directory' }
$package = 'ecc-agentshield@1.6.0'
if ($DryRun) {
  [pscustomobject]@{ package=$package; command='scan'; path=$resolved; format='json'; mutates=$false } | ConvertTo-Json
  return
}
$nodeVersion = & node --version
if ($LASTEXITCODE -ne 0 -or [int]($nodeVersion.TrimStart('v').Split('.')[0]) -lt 20) { throw 'AgentShield requires Node.js 20+' }
$npx = Get-Command $(if ($IsWindows) { 'npx.cmd' } else { 'npx' }) -ErrorAction Stop
if ($IsWindows) {
  # Invoke JS directly: arbitrary paths must never be interpolated by cmd.exe.
  $cli = Join-Path (Split-Path $npx.Source) 'node_modules/npm/bin/npx-cli.js'
  if (-not (Test-Path -LiteralPath $cli)) { throw "Cannot locate npm npx-cli.js beside $($npx.Source)" }
  & node $cli --yes $package scan --path $resolved --format json
} else {
  & $npx.Source --yes $package scan --path $resolved --format json
}
exit $LASTEXITCODE
