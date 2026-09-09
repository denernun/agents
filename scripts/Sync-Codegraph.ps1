<# Targeted CodeGraph refresh. Preserves other MCPs and backs up legacy skills.
   -Global adds a cwd-neutral Codex fallback and refreshes only graph skills.
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
$graphSkills = @('codegraph','explore-codebase','debug-issue','refactor-safely','review-changes')
$template = Get-Content (Join-Path $HubPath 'mcp/codegraph.template.json') -Raw
if ($Global) {
  $server = ($template | ConvertFrom-Json).mcpServers.codegraph
  # No pinned cwd/path: project config overrides this fallback; explicit
  # projectPath is required when the current directory has no index.
  $server.args = @('/c','codegraph','serve','--mcp')
  $server.PSObject.Properties.Remove('cwd')
  Invoke-HubConfig @{path=(Join-Path (Get-CodexHome) 'config.toml'); format='toml'; servers=@{codegraph=$server}; partial=$true; dry=[bool]$DryRun}
  foreach ($name in $graphSkills) {
    $source = Join-Path $HubPath "skills/$name/SKILL.md"
    if (-not (Test-HubSkill (Split-Path $source))) { throw "Invalid skill: $name" }
    $destination = Join-Path $env:USERPROFILE ".agents/skills/$name/SKILL.md"
    $skillDirectory = Split-Path $destination
    if (Test-HubOwnedLink -Path $skillDirectory -HubPath $HubPath) { continue }
    $item = Get-Item -LiteralPath $skillDirectory -Force -ErrorAction SilentlyContinue
    if ($item -and ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
      Write-Warning "Preserved external skill link: $skillDirectory"
      continue
    }
    if (Test-Path $destination) {
      $identical = (Get-FileHash $source).Hash -eq (Get-FileHash $destination).Hash
      $old = Get-Content $destination -Raw
      if (-not $identical -and (-not $AdoptLegacySkills -or $old -notmatch 'get_minimal_context|code-review-graph')) {
        Write-Warning "Preserved customized skill: $destination"
        continue
      }
      if (-not $DryRun) {
        $backup = Join-Path $HubPath ('.agenthub-state/skill-backups/' + [guid]::NewGuid().ToString('N'))
        New-Item -ItemType Directory -Path $backup -Force | Out-Null
        $expected = [IO.Path]::GetFullPath((Join-Path $env:USERPROFILE '.agents/skills')) + [IO.Path]::DirectorySeparatorChar
        if (-not ([IO.Path]::GetFullPath($skillDirectory)).StartsWith($expected, [StringComparison]::OrdinalIgnoreCase)) { throw 'Skill path outside expected root' }
        Move-Item -LiteralPath $skillDirectory -Destination (Join-Path $backup $name)
      }
    }
    if ($DryRun) { Write-Host "[dry] sync $destination"; continue }
    New-JunctionOrCopy -LinkPath $skillDirectory -TargetPath (Split-Path $source)
    Write-Host "Synced graph skill: $name"
  }
}
$configs = @{
  '.cursor/mcp.json'='mcpServers'; '.mcp.json'='mcpServers';
  '.codex/config.toml'='toml'; 'opencode.json'='mcp';
  '.agents/mcp_config.json'='mcpServers'; '.vscode/mcp.json'='servers';
  '.kiro/settings/mcp.json'='mcpServers'; '.devin/mcp_config.json'='mcpServers'
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
  foreach ($relative in @('.agents/skills','.cursor/skills','.claude/skills','.opencode/skills','.github/skills','.kiro/skills','.devin/skills')) {
    if (Test-Path (Join-Path $repo "$relative/explore-codebase")) {
      New-JunctionOrCopy -LinkPath (Join-Path $repo "$relative/codegraph") -TargetPath (Join-Path $HubPath 'skills/codegraph') -DryRun:$DryRun
    }
  }
  if ($Initialize) { Ensure-CodegraphInit -RepoPath $repo -Skills @('codegraph') -DryRun:$DryRun }
}
