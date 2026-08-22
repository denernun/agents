<#
.SYNOPSIS
  Inventory of agent instruction files and MCP configs under the product roots.
#>
[CmdletBinding()]
param(
  [string[]]$Roots = @('D:\SISTEMAS\ERPCLASS', 'D:\SISTEMAS\NFECLASS', 'D:\SISTEMAS\MOBICLASS', 'D:\SISTEMAS\SHOPCLASS')
)

$rows = @()
foreach ($root in $Roots) {
  if (-not (Test-Path $root)) { continue }
  Get-ChildItem $root -Directory | ForEach-Object {
    $p = $_.FullName
    $name = $_.Name
    foreach ($f in @('AGENTS.md', '.cursorrules', 'GEMINI.md', '.github\copilot-instructions.md', '.agents\rules\stack-pointer.md', '.kiro\steering\stack-pointer.md')) {
      $fp = Join-Path $p $f
      if (Test-Path $fp) {
        $len = (Get-Item $fp).Length
        $rows += [pscustomobject]@{ Project = $name; File = $f; KB = [math]::Round($len / 1KB, 1) }
      }
    }
    $rulesDir = Join-Path $p '.cursor\rules'
    if (Test-Path $rulesDir) {
      Get-ChildItem $rulesDir -File -ErrorAction SilentlyContinue | ForEach-Object {
        $rows += [pscustomobject]@{ Project = $name; File = "rule:$($_.Name)"; KB = [math]::Round($_.Length / 1KB, 1) }
      }
    }
    # MCP configs: project-root opencode.json / .mcp.json
    # plus mcp.json / mcp_config.json under any IDE folder
    foreach ($rel in @('opencode.json', '.mcp.json')) {
      $fp = Join-Path $p $rel
      if (Test-Path $fp) {
        $rows += [pscustomobject]@{ Project = $name; File = "mcp:$rel"; KB = [math]::Round((Get-Item $fp).Length / 1KB, 1) }
      }
    }
    Get-ChildItem $p -Recurse -Force -Include 'mcp.json', 'mcp_config.json' -ErrorAction SilentlyContinue |
      Where-Object { $_.FullName -notmatch 'node_modules|\.git\\' } |
      ForEach-Object {
        $rel = $_.FullName.Substring($p.Length + 1)
        $rows += [pscustomobject]@{ Project = $name; File = "mcp:$rel"; KB = [math]::Round($_.Length / 1KB, 1) }
      }
  }
}
$rows | Format-Table -AutoSize
Write-Host "Total rows: $($rows.Count)"

# Always-on candidates (exclude mcp:* entries)
$alwaysOn = $rows | Where-Object { $_.File -notlike 'mcp:*' }
$fat = $alwaysOn | Where-Object { $_.KB -gt 2 }
if ($fat) {
  Write-Host ""
  Write-Host "AVISO — always-on > 2 KB (manter organizado; rode Install-AgentHub.ps1):" -ForegroundColor Yellow
  $fat | Sort-Object KB -Descending | Format-Table -AutoSize
  Write-Host "Ver: docs/CONTEXT-HYGIENE.md" -ForegroundColor Yellow
} else {
  Write-Host ""
  Write-Host "OK — nenhum always-on > 2 KB." -ForegroundColor Green
}
