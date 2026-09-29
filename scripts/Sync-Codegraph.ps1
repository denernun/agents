<# Targeted CodeGraph refresh. Preserves other MCPs and backs up legacy skills.
   -Global refreshes graph skills in user-level skill roots and removes the old
   cwd-neutral Codex MCP fallback; CodeGraph MCP remains project-scoped.
   -Projects takes exact repository/worktree roots; never scans parent indexes.
   Indexing is explicit via -Initialize. No upstream `codegraph install` call. #>
[CmdletBinding()]
param(
  [string]$HubPath = (Split-Path -Parent $PSScriptRoot),
  [string[]]$Projects = @(),
  [switch]$Global,
  [switch]$Initialize,
  [switch]$AdoptLegacySkills,
  [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'AgentHub.Common.ps1')
Import-HubFunctions
[void](Import-HubDotEnv -HubPath $HubPath)
$graphSkills = @('codegraph','explore-codebase','debug-issue','refactor-safely','review-changes')
$template = Get-Content (Join-Path $HubPath 'mcp/codegraph.template.json') -Raw
if ($Global) {
  if ($AdoptLegacySkills) { Write-Warning '-AdoptLegacySkills is obsolete; manual global skills are preserved by the current installer.' }
  $cat = Get-Content (Join-Path $HubPath 'catalog/projects.json') -Raw | ConvertFrom-Json
  $policy = Resolve-IdePolicy -Catalog $cat
  $ides = Get-DetectedIdes -Allowed @($policy.Allowed) -Excluded @($policy.Excluded)
  Link-GlobalSkills -HubPath $HubPath -Catalog $cat -Ides $ides -SkillNames $graphSkills -DryRun:$DryRun
  $codexConfig = Join-Path (Get-CodexHome) 'config.toml'
  if (Test-Path $codexConfig) {
    Invoke-HubConfig @{path=$codexConfig; format='toml'; legacy_global=@('codegraph'); remove=$true; dry=[bool]$DryRun}
  }
}
$configs = @{
  '.cursor/mcp.json'='mcpServers'; '.mcp.json'='mcpServers';
  '.codex/config.toml'='toml'; 'opencode.json'='mcp';
  '.agents/mcp_config.json'='mcpServers'; '.vscode/mcp.json'='servers';
  '.devin/mcp_config.json'='mcpServers'
}
foreach ($project in $Projects) {
  $repo = (Resolve-Path -LiteralPath $project).Path
  $server = (Expand-McpTemplate -Content $template -Vars @{REPO=$repo} -JsonEscape | ConvertFrom-Json).mcpServers.codegraph
  foreach ($relative in $configs.Keys) {
    $file = Join-Path $repo $relative
    if (-not (Test-Path -LiteralPath $file)) { continue }
    $request = @{path=$file; servers=@{codegraph=$server}; managed=@('codegraph'); partial=$true; adopt=$true; dry=[bool]$DryRun}
    if ($configs[$relative] -eq 'toml') { $request.format='toml' }
    else {
      $request.property=$configs[$relative]
      if ($request.property -eq 'mcp') { $request.servers=ConvertTo-OpenCodeMcpServers -Servers @{codegraph=$server} }
    }
    Invoke-HubConfig $request
  }
  # Add the graph skill wherever the hub already installed navigation skills.
  $graphRoots = Get-IdeSkillRoots -Ides @((Get-IdeRegistry).Keys)
  foreach ($relative in $graphRoots.Keys) {
    if (Test-Path (Join-Path $repo "$relative/explore-codebase")) {
      $mode = $graphRoots[$relative]
      New-JunctionOrCopy -LinkPath (Join-Path $repo "$relative/codegraph") -TargetPath (Join-Path $HubPath 'skills/codegraph') -DryRun:$DryRun -ForceCopy:($mode -eq 'Copy') -Symlink:($mode -eq 'SymbolicLink')
    }
  }
  if ($Initialize) { Ensure-CodegraphInit -RepoPath $repo -Skills @('codegraph') -DryRun:$DryRun }
}
