$ErrorActionPreference='Stop'
Set-StrictMode -Version Latest
$sourceHub = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $sourceHub 'scripts/AgentHub.Common.ps1')
Import-HubFunctions
$AdoptLegacyConfigs=$false
$testRoot=Join-Path $sourceHub ('.audit-output/tests-' + [guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $testRoot -Force | Out-Null
$HubPath=Join-Path $testRoot 'hub'
New-Item -ItemType Directory -Path $HubPath -Force | Out-Null
Copy-Item (Join-Path $sourceHub 'mcp') $HubPath -Recurse
$repo=Join-Path $testRoot 'sample-app'
New-Item -ItemType Directory -Path $repo | Out-Null
Set-Content (Join-Path $repo 'package.json') '{"dependencies":{"@angular/core":"20"}}'
$cat=Get-Content (Join-Path $sourceHub 'catalog/projects.json') -Raw | ConvertFrom-Json
$families=@{};foreach($p in $cat.families.PSObject.Properties){$families[$p.Name]=$p.Value}
function Assert($condition, $message) { if(-not $condition){throw $message} }
Assert ((Get-ProjectFamily -Name 'sample-app' -Families $families -RepoPath $repo) -eq 'angular') 'Angular app misclassified'
Assert ((Get-ProjectFamily -Name 'sample-app' -Families $families -RepoPath $repo -Overrides ([pscustomobject]@{'sample-app'='minimal'})) -eq 'minimal') 'Override not applied'
$vars=@{HUB=$HubPath;REPO=$repo;CONTEXT7_API_KEY=''}
$names=@('codegraph','context7','filesystem','playwright','coreui')
Write-McpConfigs -RepoPath $repo -Ides @('Cursor','Claude','Codex','OpenCode','Antigravity') -Vars $vars -ServerNames $names -ManagedServers $names -SkipIdes $null
$claude=Get-Content (Join-Path $repo '.mcp.json') -Raw | ConvertFrom-Json
Assert (@($claude.mcpServers.PSObject.Properties).Count -eq 5) 'Claude lost MCPs when Cursor active'
Assert (Test-Path (Join-Path $repo '.codex/config.toml')) 'Codex project config missing'
$before=Get-FileHash (Join-Path $repo '.cursor/mcp.json')
Write-McpConfigs -RepoPath $repo -Ides @('Cursor','Claude','Codex','OpenCode','Antigravity') -Vars $vars -ServerNames $names -ManagedServers $names -SkipIdes $null
Assert ((Get-FileHash (Join-Path $repo '.cursor/mcp.json')).Hash -eq $before.Hash) 'Repeated install changes JSON'
& (Join-Path $sourceHub 'scripts/Sync-Codegraph.ps1') -HubPath $HubPath -Projects @($repo)
$refreshed=Get-Content (Join-Path $repo '.cursor/mcp.json') -Raw | ConvertFrom-Json
Assert (@($refreshed.mcpServers.PSObject.Properties).Count -eq 5) 'Targeted refresh removed other MCPs'
Assert ($refreshed.mcpServers.codegraph.env.DO_NOT_TRACK -eq '1') 'CodeGraph telemetry not disabled'
Assert (@($cat.families.delphi.skills) -contains 'codegraph') 'Delphi initialization not enabled'
# Shared skills survive excluding Antigravity while Codex remains active.
$skill=Join-Path $HubPath 'skills/test';New-Item -ItemType Directory -Path $skill -Force | Out-Null
Set-Content (Join-Path $skill 'SKILL.md') "---`nname: test`ndescription: Test skill.`n---`nBody."
Link-ProjectSkills -RepoPath $repo -HubPath $HubPath -SkillNames @('test') -Ides @('Codex')
Assert (Test-Path (Join-Path $repo '.agents/skills/test/SKILL.md')) 'Codex-only skills missing'
Remove-HubIdeArtifacts -RepoPath $repo -Ide Antigravity -ActiveIdes @('Codex')
Assert (Test-Path (Join-Path $repo '.agents/skills/test/SKILL.md')) 'Shared skills removed'
$manual=Join-Path $testRoot 'manual';New-Item -ItemType Directory -Path $manual | Out-Null
$external=Join-Path $repo '.agents/skills/manual';New-Item -ItemType Junction -Path $external -Target $manual | Out-Null
Remove-HubIdeArtifacts -RepoPath $repo -Ide Codex
Assert (Test-Path $external) 'Manual junction removed'
Assert (-not (Test-Path (Join-Path $repo '.agents/skills/test'))) 'Hub junction remained'
Assert (Test-Path $skill) 'Junction cleanup deleted source'
Remove-HubIdeArtifacts -RepoPath $repo -Ide OpenCode
$oc=Get-Content (Join-Path $repo 'opencode.json') -Raw | ConvertFrom-Json
Assert (@($oc.mcp.PSObject.Properties).Count -eq 0) 'OpenCode uninstall incomplete'
Assert (Test-HubSkill (Join-Path $sourceHub 'skills/delphi-erpclass')) 'Delphi metadata invalid'
# An empty graph directory must not suppress initialization; a database must.
$emptyProject=Join-Path $testRoot 'empty-index'
New-Item -ItemType Directory (Join-Path $emptyProject '.codegraph') -Force | Out-Null
$script:initCalls=0
function Invoke-FakeCodegraph {
  $script:initCalls++
  Assert ($env:DO_NOT_TRACK -eq '1') 'Initialization leaked telemetry'
  Assert ($args -contains '--yes') 'Initialization can prompt'
  Set-Content (Join-Path $args[1] '.codegraph/codegraph.db') 'fixture'
  $global:LASTEXITCODE=0
}
function Get-CodegraphExe { return 'Invoke-FakeCodegraph' }
$prior=[Environment]::GetEnvironmentVariable('DO_NOT_TRACK','Process')
Ensure-CodegraphInit -RepoPath $emptyProject -Skills @('codegraph')
Ensure-CodegraphInit -RepoPath $emptyProject -Skills @('codegraph')
Assert ($script:initCalls -eq 1) 'Empty index skipped or existing index rebuilt'
Assert ([string][Environment]::GetEnvironmentVariable('DO_NOT_TRACK','Process') -eq [string]$prior) 'Initialization changed caller environment'
Write-Host 'Integration checks passed. Fixtures retained under .audit-output for inspection.'
