<# Read-only audit of user-scope skills and global MCPs for detected IDEs. #>
[CmdletBinding()]
param(
  [string]$HubPath = (Split-Path -Parent $PSScriptRoot),
  [string[]]$Ides = @(),
  [switch]$Json
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'AgentHub.Common.ps1')
Import-HubFunctions
[void](Import-HubDotEnv -HubPath $HubPath)
$catalog = Get-Content -LiteralPath (Join-Path $HubPath 'catalog/projects.json') -Raw | ConvertFrom-Json
$policy = Resolve-IdePolicy -Catalog $catalog
if (-not $Ides.Count) {
  $Ides = Get-DetectedIdes -Allowed @($policy.Allowed) -Excluded @($policy.Excluded) -IncludeQoder:([bool]$catalog.qoderOptIn)
}

$globalSkills = @(Get-GlobalSkillNames -Catalog $catalog)
$skillRows = [System.Collections.Generic.List[object]]::new()
foreach ($ide in $Ides) {
  foreach ($root in (Get-IdeGlobalSkillRoots -Ides @($ide)).Keys) {
    $missing = @($globalSkills | Where-Object { -not (Test-HubSkill (Join-Path $root $_)) })
    $skillRows.Add([pscustomobject]@{
      ide = $ide
      root = $root
      expected = $globalSkills.Count
      missing = $missing
      filesystem = if ($missing.Count) { 'incomplete' } else { 'complete' }
      discovery = 'not observed in the agent runtime'
    })
  }
}

$globalMcpNames = @(Get-JsonProperty $catalog.mcp 'global')
$mcpRows = [System.Collections.Generic.List[object]]::new()
$python = Get-HubPython
foreach ($path in (Get-IdeGlobalMcpTargets -Ides $Ides).Keys) {
  $target = (Get-IdeGlobalMcpTargets -Ides $Ides)[$path]
  if (($target.Ides -contains 'Codex') -and (Test-CodexContext7PluginEnabled)) {
    $mcpRows.Add([pscustomobject]@{ides=$target.Ides;path=$path;expected=$globalMcpNames;missing=@();status='provided by enabled Context7 Codex plugin'})
    continue
  }
  $configured = @()
  $syntax = 'missing'
  if (Test-Path -LiteralPath $path) {
    try {
      if ($target.Format -eq 'toml') {
        $request=@{action='inspect-toml';path=$path} | ConvertTo-Json -Compress
        $reply=$request | & $python (Join-Path $PSScriptRoot 'agenthub_config.py') | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) { throw 'Invalid TOML' }
        $configured=@($reply.servers)
      } else {
        $request=@{action='inspect-json';path=$path;property=$target.Property} | ConvertTo-Json -Compress
        $reply=$request | & $python (Join-Path $PSScriptRoot 'agenthub_config.py') | ConvertFrom-Json
        if ($LASTEXITCODE -ne 0) { throw 'Invalid JSON' }
        $configured=@($reply.servers)
      }
      $syntax='valid'
    } catch { $syntax='invalid' }
  }
  $missing=@($globalMcpNames | Where-Object { $configured -notcontains $_ })
  $mcpRows.Add([pscustomobject]@{ides=$target.Ides;path=$path;expected=$globalMcpNames;missing=$missing;status=$syntax})
}

$result=[pscustomobject]@{ides=$Ides;globalSkills=$skillRows;globalMcp=$mcpRows;runtimeDiscovery='not observed'}
if ($Json) {
  $result | ConvertTo-Json -Depth 8
} else {
  foreach ($row in $skillRows) {
    Write-Output "$($row.ide) skills [$($row.root)]: $($row.filesystem); missing=$($row.missing -join ', ')"
  }
  foreach ($row in $mcpRows) {
    Write-Output "$($row.ides -join '+') MCP [$($row.path)]: $($row.status); missing=$($row.missing -join ', ')"
  }
  Write-Output 'File checks do not prove runtime discovery; verify /skills and the MCP panel in each agent.'
}
if (@($skillRows | Where-Object { $_.missing.Count }).Count -gt 0 -or @($mcpRows | Where-Object { $_.missing.Count -gt 0 -or $_.status -eq 'invalid' }).Count -gt 0) { exit 1 }
exit 0
