<#
.SYNOPSIS
  Converte hooks .sh do code-review-graph para .ps1 no Cursor (Windows).

.DESCRIPTION
  O code-review-graph cria hooks .sh que abrem múltiplas janelas Git Bash no Windows.
  Este script converte os hooks para PowerShell (.ps1) que executa silenciosamente.

.EXAMPLE
  .\Fix-CursorHooks.ps1
#>
[CmdletBinding()]
param([switch]$DryRun)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

$cursorHooksDir = Join-Path $env:USERPROFILE '.cursor\hooks'

if (-not (Test-Path $cursorHooksDir)) {
  Write-Host "Cursor hooks directory not found: $cursorHooksDir"
  exit 0
}

Write-Host "Converting Cursor hooks from .sh to .ps1..."

# crg-session-start
$shPath = Join-Path $cursorHooksDir 'crg-session-start.sh'
$ps1Path = Join-Path $cursorHooksDir 'crg-session-start.ps1'
if (Test-Path $shPath) {
  $content = @'
# code-review-graph: show graph status on session start (Cursor hook)
# Fails gracefully — never blocks the editor.

$ErrorActionPreference = 'SilentlyContinue'
$null = $input
try {
    $output = & code-review-graph status 2>&1 | Out-String
} catch {
    $output = "graph not built yet"
}
$response = @{ message = $output.Trim(); passed = $true } | ConvertTo-Json -Compress
Write-Output $response
exit 0
'@
  if ($DryRun) {
    Write-Host "  [dry] convert crg-session-start.sh -> .ps1"
  } else {
    Set-Content -Path $ps1Path -Value $content -Encoding UTF8
    Remove-Item $shPath -Force
    Write-Host "  ✓ converted crg-session-start.sh -> .ps1"
  }
}

# crg-update
$shPath = Join-Path $cursorHooksDir 'crg-update.sh'
$ps1Path = Join-Path $cursorHooksDir 'crg-update.ps1'
if (Test-Path $shPath) {
  $content = @'
# code-review-graph: auto-update graph after file edits (Cursor hook)
# Fails gracefully — never blocks the editor.

$ErrorActionPreference = 'SilentlyContinue'
$null = $input
try {
    $output = & code-review-graph update --skip-flows 2>&1
} catch {
    $output = ""
}
$response = @{ message = 'graph updated'; passed = $true } | ConvertTo-Json -Compress
Write-Output $response
exit 0
'@
  if ($DryRun) {
    Write-Host "  [dry] convert crg-update.sh -> .ps1"
  } else {
    Set-Content -Path $ps1Path -Value $content -Encoding UTF8
    Remove-Item $shPath -Force
    Write-Host "  ✓ converted crg-update.sh -> .ps1"
  }
}

# crg-pre-commit
$shPath = Join-Path $cursorHooksDir 'crg-pre-commit.sh'
$ps1Path = Join-Path $cursorHooksDir 'crg-pre-commit.ps1'
if (Test-Path $shPath) {
  $content = @'
# code-review-graph: detect changes before git commit (Cursor hook)
# Fails gracefully — never blocks the editor.

$ErrorActionPreference = 'SilentlyContinue'
$null = $input
try {
    $output = & code-review-graph detect-changes --brief 2>&1 | Out-String
} catch {
    $output = ""
}
$response = @{ message = $output.Trim(); passed = $true } | ConvertTo-Json -Compress
Write-Output $response
exit 0
'@
  if ($DryRun) {
    Write-Host "  [dry] convert crg-pre-commit.sh -> .ps1"
  } else {
    Set-Content -Path $ps1Path -Value $content -Encoding UTF8
    Remove-Item $shPath -Force
    Write-Host "  ✓ converted crg-pre-commit.sh -> .ps1"
  }
}

Write-Host "`nDone! PowerShell hooks will run silently without opening terminal windows."
Write-Host "Restart Cursor if it's currently open to reload the hooks."
