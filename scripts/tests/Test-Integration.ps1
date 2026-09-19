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
$families = Get-CatalogFamilies -Catalog $cat
function Assert($condition, $message) { if(-not $condition){throw $message} }
Assert ((Get-ProjectFamily -Name 'sample-app' -Families $families -RepoPath $repo) -eq 'angular') 'Angular app misclassified'
Assert ((Get-ProjectFamily -Name 'sample-app' -Families $families -RepoPath $repo -Overrides ([pscustomobject]@{'sample-app'='minimal'})) -eq 'minimal') 'Override not applied'
$vars=@{HUB=$HubPath;REPO=$repo;CONTEXT7_API_KEY=''}
$names=@('codegraph','context7','filesystem','playwright','coreui')
Write-McpConfigs -RepoPath $repo -Ides @('Cursor','Claude','Codex','OpenCode','Antigravity') -Vars $vars -ServerNames $names -ManagedServers $names -SkipIdes $null
$claude=Get-Content (Join-Path $repo '.mcp.json') -Raw | ConvertFrom-Json
Assert (@($claude.mcpServers.PSObject.Properties).Count -eq 5) 'Claude lost MCPs when Cursor active'
Assert (($claude.mcpServers.coreui.args -join ' ') -match '--framework bootstrap') 'CoreUI MCP must use Bootstrap framework reference'
Assert (Test-Path (Join-Path $repo '.codex/config.toml')) 'Codex project config missing'
$before=Get-FileHash (Join-Path $repo '.cursor/mcp.json')
Write-McpConfigs -RepoPath $repo -Ides @('Cursor','Claude','Codex','OpenCode','Antigravity') -Vars $vars -ServerNames $names -ManagedServers $names -SkipIdes $null
Assert ((Get-FileHash (Join-Path $repo '.cursor/mcp.json')).Hash -eq $before.Hash) 'Repeated install changes JSON'
& (Join-Path $sourceHub 'scripts/Sync-Codegraph.ps1') -HubPath $HubPath -Projects @($repo)
$refreshed=Get-Content (Join-Path $repo '.cursor/mcp.json') -Raw | ConvertFrom-Json
Assert (@($refreshed.mcpServers.PSObject.Properties).Count -eq 5) 'Targeted refresh removed other MCPs'
Assert ($refreshed.mcpServers.codegraph.env.DO_NOT_TRACK -eq '1') 'CodeGraph telemetry not disabled'
Assert (@($cat.families.delphi.skills) -contains 'codegraph') 'Delphi initialization not enabled'
Assert (@($cat.excludeProjectNames) -notcontains 'erpclass-erp') 'Delphi ERP is still excluded from installation'
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

# --- IDE registry: one source of truth for paths and the copy-vs-junction rule
$registry=Get-IdeRegistry
Assert ($registry.Contains('Kiro')) 'Registry lost Kiro'
Assert ($registry['Kiro'].CopySkills) 'Kiro must be copy-based: it does not follow junctions'
Assert (-not $registry['Cursor'].CopySkills) 'Cursor should stay junction-based'
# Codex and Antigravity deliberately share .agents/skills: the root must appear once.
$sharedRoots=Get-IdeSkillRoots -Ides @('Codex','Antigravity')
Assert (@($sharedRoots.Keys).Count -eq 1) 'Shared .agents/skills root was not de-duplicated'
Assert ((Get-IdeSkillRoots -Ides @('Kiro'))['.kiro/skills']) 'Kiro root lost its copy flag'

# --- Family resolution comes from the catalog, and a catch-all is always last
$ordered=[ordered]@{
  fallback=[pscustomobject]@{ match=@('*') }
  specific=[pscustomobject]@{ match=@('*-api') }
}
Assert ((Get-ProjectFamily -Name 'x-api' -Families $ordered) -eq 'specific') 'Catch-all declared first must not win'
Assert ((Get-ProjectFamily -Name 'whatever' -Families $ordered) -eq 'fallback') 'Catch-all not used as fallback'

# --- Project detection used by -ProjectPath and by the main loop
$notRepo=Join-Path $testRoot 'plain-folder'
New-Item -ItemType Directory -Path $notRepo -Force | Out-Null
Assert (-not (Test-ProjectDirectory -Path $notRepo)) 'Empty folder must not look like a project'
Assert (Test-ProjectDirectory -Path $repo) 'Folder with package.json must look like a project'
Assert (Test-ProjectDirectory -Path $notRepo -Family 'android') 'Android family must be accepted without markers'

# --- Copy roots must be idempotent: the second pass may not re-copy
$copyTarget=Join-Path $HubPath 'skills/test'
$copyLink=Join-Path $testRoot 'copy-dest/test'
New-JunctionOrCopy -LinkPath $copyLink -TargetPath $copyTarget -ForceCopy
Assert (Test-Path (Join-Path $copyLink 'SKILL.md')) 'ForceCopy did not materialise the skill'
Assert (Test-CopyUpToDate -LinkPath $copyLink -TargetPath $copyTarget) 'Fresh copy reported as out of date'
$stamp=(Get-Item (Join-Path $copyLink 'SKILL.md')).LastWriteTimeUtc
New-JunctionOrCopy -LinkPath $copyLink -TargetPath $copyTarget -ForceCopy
Assert ((Get-Item (Join-Path $copyLink 'SKILL.md')).LastWriteTimeUtc -eq $stamp) 'Identical copy was rewritten'
Set-Content (Join-Path $copyTarget 'SKILL.md') "---`nname: test`ndescription: Changed.`n---`nNew body."
Assert (-not (Test-CopyUpToDate -LinkPath $copyLink -TargetPath $copyTarget)) 'Changed source not detected'

Write-Host 'Integration checks passed. Fixtures retained under .audit-output for inspection.'

# Explicit success signal: $LASTEXITCODE would otherwise leak from the last
# native call (python/git) and report failure on a passing run.
exit 0
