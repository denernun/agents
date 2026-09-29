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
Assert (@($cat.globalSkillExtras) -contains 'codegraph') 'Global CodeGraph skill was not enabled'
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
Assert (-not $registry.Contains('Kiro')) 'Kiro support was dropped; it must not return to the registry'
Assert (-not $registry['Cursor'].CopySkills) 'Cursor should stay junction-based'
# Codex and Antigravity deliberately share .agents/skills: the root must appear once.
$sharedRoots=Get-IdeSkillRoots -Ides @('Codex','Antigravity')
Assert (@($sharedRoots.Keys).Count -eq 1) 'Shared .agents/skills root was not de-duplicated'
Assert ($sharedRoots['.agents/skills'] -eq 'SymbolicLink') 'Antigravity skips junctions: shared .agents/skills must use symlinks'
Assert ((Get-IdeSkillRoots -Ides @('Cursor'))['.cursor/skills'] -eq 'Junction') 'Cursor root should stay junction-based'

# --- Cross-project skills and Context7 install at user scope for every IDE
$globalSkills=@(Get-GlobalSkillNames -Catalog $cat)
Assert ($globalSkills -contains 'git-workflow-and-versioning') 'Git workflow skill is not global'
Assert ($globalSkills -contains 'browser-testing-with-devtools') 'Browser testing skill is not global'
Assert ($globalSkills -contains 'e2e-testing') 'Playwright E2E skill is not global'
Assert (@(Get-JsonProperty $cat.mcp 'global') -contains 'context7') 'Context7 is not declared global'
Assert (@(Get-CatalogMcpCommon -Catalog $cat) -notcontains 'context7') 'Context7 remains in project-common MCPs'
foreach ($skillName in $globalSkills) {
  $skillDir=Join-Path $HubPath "skills/$skillName"
  New-Item -ItemType Directory -Path $skillDir -Force | Out-Null
  Set-Content (Join-Path $skillDir 'SKILL.md') "---`nname: $skillName`ndescription: Integration fixture.`n---`nBody."
}
$oldProfile=$env:USERPROFILE; $oldAppData=$env:APPDATA; $oldXdg=$env:XDG_CONFIG_HOME
$oldCodexHome=$env:CODEX_HOME; $oldClaudeConfig=$env:CLAUDE_CONFIG_DIR
try {
  $env:USERPROFILE=Join-Path $testRoot 'user-profile'
  $env:APPDATA=Join-Path $testRoot 'app-data'
  $env:XDG_CONFIG_HOME=Join-Path $testRoot 'xdg-config'
  $env:CODEX_HOME=Join-Path $testRoot 'codex-home'
  $env:CLAUDE_CONFIG_DIR=Join-Path $testRoot 'claude-config'
  $allIdes=@($registry.Keys)
$globalRoots=Get-IdeGlobalSkillRoots -Ides $allIdes
  foreach ($ide in $allIdes) {
    Assert (@((Get-IdeGlobalSkillRoots -Ides @($ide)).Keys).Count -gt 0) "$ide has no global skill root"
  }
  Link-GlobalSkills -HubPath $HubPath -Catalog $cat -Ides $allIdes
  $agyLink=Get-Item (Join-Path $env:USERPROFILE ".gemini/antigravity-cli/skills/$($globalSkills[0])") -Force
  Assert ($agyLink.LinkType -eq 'SymbolicLink' -or (Test-Path (Join-Path $agyLink.FullName '.agenthub-managed'))) 'Antigravity global skill is a junction: agy skips junctions'
  foreach ($root in $globalRoots.Keys) {
    foreach ($skillName in $globalSkills) {
      Assert (Test-Path (Join-Path $root "$skillName/SKILL.md")) "$skillName missing from global root $root"
    }
  }

  $globalTargets=Get-IdeGlobalMcpTargets -Ides $allIdes
  foreach ($ide in $allIdes) {
    Assert (@((Get-IdeGlobalMcpTargets -Ides @($ide)).Keys).Count -gt 0) "$ide has no global MCP target"
  }
  $globalVars=@{HUB=$HubPath;REPO=$repo;CONTEXT7_API_KEY=''}
  $openCodeTarget=@((Get-IdeGlobalMcpTargets -Ides @('OpenCode')).Keys)[0]
  New-Item -ItemType Directory -Path (Split-Path $openCodeTarget) -Force | Out-Null
  Set-Content -LiteralPath $openCodeTarget '{"mcp":{"manual":{"type":"local","command":["keep-me"]}}}'
  Write-GlobalMcpConfigs -HubPath $HubPath -Ides $allIdes -Vars $globalVars -ServerNames @($cat.mcp.global)
  foreach ($path in $globalTargets.Keys) {
    $target=$globalTargets[$path]
    if ($target.Format -eq 'toml') {
      $request=@{action='inspect-toml';path=$path} | ConvertTo-Json -Compress
      $reply=$request | & (Get-HubPython) (Join-Path (Split-Path -Parent $PSScriptRoot) 'agenthub_config.py') | ConvertFrom-Json
      Assert (@($reply.servers) -contains 'context7') 'Global Context7 missing from Codex config'
    } else {
      $obj=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
      Assert ($obj.($target.Property).PSObject.Properties.Name -contains 'context7') "Global Context7 missing from $path"
    }
  }
  $openCodeConfig=Get-Content -LiteralPath $openCodeTarget -Raw | ConvertFrom-Json
  Assert ($openCodeConfig.mcp.manual.command[0] -eq 'keep-me') 'Global OpenCode MCP merge removed a manual server'

  $codexPluginHome=Join-Path $testRoot 'codex-with-context7-plugin'
  New-Item -ItemType Directory -Path $codexPluginHome -Force | Out-Null
  Set-Content (Join-Path $codexPluginHome 'config.toml') "[plugins.`"context7@claude-plugins-official`"]`nenabled = true"
  $env:CODEX_HOME=$codexPluginHome
  Write-GlobalMcpConfigs -HubPath $HubPath -Ides @('Codex') -Vars $globalVars -ServerNames @('context7')
  $pluginConfig=Get-Content -LiteralPath (Join-Path $codexPluginHome 'config.toml') -Raw
  Assert ($pluginConfig -notmatch '\[mcp_servers\."context7"\]') 'Codex Context7 plugin was duplicated as an MCP server'

  # Claude: enabling the official plugin prunes the hub-written context7 entry
  # but keeps a manual server in the same file.
  $claudeTarget=@((Get-IdeGlobalMcpTargets -Ides @('Claude')).Keys)[0]
  $claudeJson=Get-Content -LiteralPath $claudeTarget -Raw | ConvertFrom-Json
  $claudeJson.mcpServers | Add-Member -NotePropertyName manual -NotePropertyValue ([pscustomobject]@{command='keep-me'}) -Force
  Set-Content -LiteralPath $claudeTarget -Value ($claudeJson | ConvertTo-Json -Depth 10)
  Set-Content -LiteralPath (Join-Path $env:CLAUDE_CONFIG_DIR 'settings.json') '{"enabledPlugins":{"context7@claude-plugins-official":true}}'
  Write-GlobalMcpConfigs -HubPath $HubPath -Ides @('Claude') -Vars $globalVars -ServerNames @('context7')
  $claudeAfter=Get-Content -LiteralPath $claudeTarget -Raw | ConvertFrom-Json
  Assert (-not $claudeAfter.mcpServers.PSObject.Properties['context7']) 'Claude Context7 plugin was duplicated as an MCP server'
  Assert ($claudeAfter.mcpServers.manual.command -eq 'keep-me') 'Claude Context7 prune removed a manual server'
} finally {
  $env:USERPROFILE=$oldProfile; $env:APPDATA=$oldAppData; $env:XDG_CONFIG_HOME=$oldXdg
  $env:CODEX_HOME=$oldCodexHome; $env:CLAUDE_CONFIG_DIR=$oldClaudeConfig
}

# --- Cursor's cmd.exe hook workaround wraps only ai-memory commands
$cursorHookFixture=Join-Path $testRoot 'cursor-hooks.json'
$quotedAiMemory='"C:\Users\test\AppData\Local\ai-memory\ai-memory.exe" --data-dir "C:\Users\test\AppData\Local\ai-memory" hook --event pre-tool-use --agent cursor --server-url http://127.0.0.1:49374'
$manualHook='C:\tools\manual-hook.cmd --keep-quotes'
$hookFixture=@{hooks=@{preToolUse=@(@{type='command';command=$quotedAiMemory},@{type='command';command=$manualHook})}} | ConvertTo-Json -Depth 8
Set-Content -LiteralPath $cursorHookFixture -Value $hookFixture -Encoding UTF8
Repair-AiMemoryHookQuoting -Slug cursor -HooksPath $cursorHookFixture
$repairedHooks=Get-Content -LiteralPath $cursorHookFixture -Raw | ConvertFrom-Json
$repairedAi=[string](@($repairedHooks.hooks.preToolUse | Where-Object { $_.command -match 'ai-memory' })[0].command)
Assert ($repairedAi -notmatch '\\"C:') 'Cursor ai-memory executable quote was not repaired for cmd.exe'
Assert ($repairedAi -match '^cmd /d /s /c C:\\Users\\test\\AppData\\Local\\ai-memory\\ai-memory\.exe ') 'Cursor ai-memory command was not explicitly wrapped in cmd.exe'
Assert ((@($repairedHooks.hooks.preToolUse | Where-Object { $_.command -eq $manualHook }).Count) -eq 1) 'Repair changed an unrelated Cursor hook'
$once=Get-FileHash -LiteralPath $cursorHookFixture
Repair-AiMemoryHookQuoting -Slug cursor -HooksPath $cursorHookFixture
Assert ((Get-FileHash -LiteralPath $cursorHookFixture).Hash -eq $once.Hash) 'Cursor hook quote repair is not idempotent'

# --- Cursor imports Claude hooks but drops their separate args arrays
$claudeHooksFixture=Join-Path $testRoot 'claude-settings.json'
$claudeAiHookFixture=@{
  type='command'
  command='C:\Users\test\AppData\Local\ai-memory\ai-memory.exe'
  args=@('--data-dir','C:\Users\test\AppData\Local\ai-memory','hook','--event','pre-tool-use','--agent','claude-code','--server-url','http://127.0.0.1:49374')
}
$claudeSettingsFixture=@{
  hooks=@{
    PreToolUse=@(@{matcher='';hooks=@($claudeAiHookFixture)})
    SessionStart=@(@{hooks=@(@{type='command';command='C:\tools\manual-hook.cmd'})})
  }
  otherSetting='preserve-me'
} | ConvertTo-Json -Depth 12
Set-Content -LiteralPath $claudeHooksFixture -Value $claudeSettingsFixture -Encoding UTF8
Set-Content -LiteralPath "$claudeHooksFixture.bak.ai-memory-cursor-20000101-000000" -Value '{}'
Repair-AiMemoryClaudeHooksForCursor -SettingsPath $claudeHooksFixture
$pileupDir=Join-Path $testRoot 'ai-memory-pileup'
New-Item -ItemType Directory -Path $pileupDir -Force | Out-Null
$pileupFile=Join-Path $pileupDir 'hooks.json'
Set-Content -LiteralPath $pileupFile -Value '{}'
$i=0
foreach ($name in @('hooks.json.bak-1700000001','hooks.json.bak-1700000002','hooks.json.bak-1700000003','hooks.json.bak','hooks.json.bak-20260927','hooks.json.bak-crg-removal')) {
  $item=New-Item -ItemType File -Path (Join-Path $pileupDir $name) -Force
  $item.LastWriteTime=(Get-Date).AddMinutes($i++)
}
Remove-AiMemoryBackupPileup -Paths @($pileupFile)
$left=@(Get-ChildItem -LiteralPath $pileupDir -File | ForEach-Object Name | Sort-Object)
Assert (($left -join ',') -eq 'hooks.json,hooks.json.bak,hooks.json.bak-1700000003,hooks.json.bak-20260927,hooks.json.bak-crg-removal') "ai-memory backup prune kept the wrong files: $($left -join ',')"
$claudeBackups=@(Get-ChildItem -LiteralPath $testRoot -Filter 'claude-settings.json.bak.ai-memory-cursor*')
Assert ($claudeBackups.Count -eq 0) 'Claude hook repair must not leave backups of its own'
$repairedClaude=Get-Content -LiteralPath $claudeHooksFixture -Raw | ConvertFrom-Json
$claudeAiHook=$repairedClaude.hooks.PreToolUse[0].hooks[0]
Assert ($claudeAiHook.command -match '^cmd /d /s /c C:\\Users\\test\\AppData\\Local\\ai-memory\\ai-memory\.exe .*--event pre-tool-use.*--agent claude-code') 'Claude ai-memory hook args were not folded into its command for Cursor'
Assert (-not $claudeAiHook.PSObject.Properties['args']) 'Claude ai-memory hook retained an args array that Cursor drops'
Assert ($repairedClaude.hooks.SessionStart[0].hooks[0].command -eq 'C:\tools\manual-hook.cmd') 'Claude repair changed an unrelated hook'
Assert ($repairedClaude.otherSetting -eq 'preserve-me') 'Claude repair changed an unrelated setting'
$claudeOnce=Get-FileHash -LiteralPath $claudeHooksFixture
Repair-AiMemoryClaudeHooksForCursor -SettingsPath $claudeHooksFixture
Assert ((Get-FileHash -LiteralPath $claudeHooksFixture).Hash -eq $claudeOnce.Hash) 'Claude hook argument repair is not idempotent'

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

# --- Vendor provenance: one catalog key per upstream package, no shared names
$lists=Get-UniversalSkillLists -Catalog $cat
Assert (@($lists.Keys) -contains 'catalog.addyosmaniSkills') 'Addy Osmani selection lost its own catalog key'
Assert (@($lists['catalog.addyosmaniSkills']) -contains 'using-agent-skills') 'Addy Osmani list is empty'
Assert (@($lists['catalog.commonSkills']) -notcontains 'using-agent-skills') 'Addy Osmani skill still duplicated in commonSkills'
Assert-NoSkillNameCollisions -Lists $lists
$clash=[ordered]@{ 'catalog.a'=@('shared','x'); 'catalog.b'=@('shared') }
$collided=$false
$clashMessage=''
try { Assert-NoSkillNameCollisions -Lists $clash } catch { $collided=$true; $clashMessage=$_.Exception.Message }
Assert $collided 'A name claimed by two catalog lists was accepted'
Assert ($clashMessage -match 'shared' -and $clashMessage -match 'catalog\.b') 'Collision error does not name the skill and the winning list'
Assert-NoSkillNameCollisions -Lists ([ordered]@{ 'catalog.a'=@('dup','dup') })

# --- Project roots keep only stack/contract-specific skills
$angularSkills=@(Get-ProjectSkillNames -Catalog $cat -FamilyCfg $cat.families.angular -Family 'angular' -ProjectName 'sample-admin')
foreach ($expected in @('angular-coreui','coreui-styling','contract-first')) {
  Assert ($angularSkills -contains $expected) "Angular project lost $expected"
}
foreach ($globalName in @('using-agent-skills','unlazy','tdd','systematic-debugging','codegraph','browser-testing-with-devtools','e2e-testing')) {
  Assert ($angularSkills -notcontains $globalName) "$globalName should be user-global, not project-linked"
}
Assert (@($angularSkills).Count -eq @($angularSkills | Select-Object -Unique).Count) 'Resolved skill list has duplicates'
$optedOut=[pscustomobject]@{ skills=@('codegraph'); disabledCommonSkills=@('tdd','unlazy') }
$reduced=@(Get-ProjectSkillNames -Catalog $cat -FamilyCfg $optedOut -Family 'minimal' -ProjectName 'sample')
Assert ($reduced -notcontains 'tdd' -and $reduced -notcontains 'unlazy') 'Global workflows leaked back into the project skill set'
Assert ($reduced -notcontains 'codegraph') 'Global codegraph skill leaked back into the project skill set'

# --- AGENTS.md family label comes from catalog.roots, never hardcoded
$nestRoot=Join-Path $testRoot 'family-root/CLOUDCLASS/cloudclass-api'
New-Item -ItemType Directory -Path $nestRoot -Force | Out-Null
Assert ((Get-ProjectFamilyLabel -RepoPath $nestRoot -Catalog $cat) -eq 'CLOUDCLASS') 'Family label did not resolve the managed root folder'
$outsideRoot=Join-Path $testRoot 'elsewhere/repo'
New-Item -ItemType Directory -Path $outsideRoot -Force | Out-Null
Assert ((Get-ProjectFamilyLabel -RepoPath $outsideRoot -Catalog $cat) -eq '') 'Family label should be empty outside a managed root'
$templateFixture=Join-Path $testRoot 'agents-nestjs.md'
Set-Content -LiteralPath $templateFixture -Value "# {{PROJECT}}`n`nNestJS API - Clean Architecture / DDD ({{FAMILY}} family).`n"
$content=(Get-Content -LiteralPath $templateFixture -Raw).Replace('{{PROJECT}}','cloudclass-api').Replace('{{FAMILY}}','CLOUDCLASS')
Assert ($content -match '\(CLOUDCLASS family\)') 'AGENTS.md template did not substitute the family label'

# --- A name that moved between vendor packages is reported, not swapped quietly
$vendorA=Join-Path $HubPath 'vendor/pkg-a/skills/moved'
$vendorB=Join-Path $HubPath 'vendor/pkg-b/skills/moved'
foreach ($dir in @($vendorA,$vendorB)) {
  New-Item -ItemType Directory -Path $dir -Force | Out-Null
  Set-Content (Join-Path $dir 'SKILL.md') "---`nname: moved`ndescription: Moved skill.`n---`nBody."
}
# --- A vendor skill assigned through a family (not the top-level vendor list)
# must still be resolved by the mirror, or skills/<name> is never created.
$famVendor=Join-Path $HubPath 'vendor/fam-pkg/skills/fam-only'
New-Item -ItemType Directory -Path $famVendor -Force | Out-Null
Set-Content (Join-Path $famVendor 'SKILL.md') "---`nname: fam-only`ndescription: Family-assigned vendor skill.`n---`nBody."
$flatProvided=@(Select-VendorProvidedSkills -HubPath $HubPath -VendorRelativePath 'vendor/fam-pkg' -Candidates @('fam-only','not-there'))
Assert ($flatProvided -contains 'fam-only') 'Mirror did not resolve a family-assigned vendor skill'
Assert ($flatProvided -notcontains 'not-there') 'Mirror claimed a skill the vendor does not provide'
$nestVendor=Join-Path $HubPath 'vendor/nest-pkg/skills/category/nested-skill'
New-Item -ItemType Directory -Path $nestVendor -Force | Out-Null
Set-Content (Join-Path $nestVendor 'SKILL.md') "---`nname: nested-skill`ndescription: Nested vendor skill.`n---`nBody."
$nestProvided=@(Select-VendorProvidedSkills -HubPath $HubPath -VendorRelativePath 'vendor/nest-pkg' -Candidates @('nested-skill') -Nested)
Assert ($nestProvided -contains 'nested-skill') 'Mirror did not resolve a nested (mattpocock-layout) family skill'
Assert (@(Select-VendorProvidedSkills -HubPath $HubPath -VendorRelativePath 'vendor/does-not-exist' -Candidates @('x')).Count -eq 0) 'Missing vendor clone should yield nothing, not throw'

Assert ((Get-VendorPackageName -Path $vendorA -HubPath $HubPath) -eq 'pkg-a') 'Vendor package not derived from path'
Assert ($null -eq (Get-VendorPackageName -Path (Join-Path $HubPath 'skills/test') -HubPath $HubPath)) 'Native hub skill reported as vendor'
$movedLink=Join-Path $HubPath 'skills/moved'
New-JunctionOrCopy -LinkPath $movedLink -TargetPath $vendorA
# New-JunctionOrCopy is a simple function, so -WarningVariable is unavailable:
# capture the warning stream instead.
$repointWarning=@(& { New-JunctionOrCopy -LinkPath $movedLink -TargetPath $vendorB } 3>&1 | ForEach-Object { [string]$_ })
Assert ($repointWarning -match 'disputed between vendor packages') 'Repoint across vendor packages stayed silent'
Assert ((Get-Item $movedLink -Force).Target -contains $vendorB) 'Repoint did not take effect'

Write-Host 'Integration checks passed. Fixtures retained under .audit-output for inspection.'

# Explicit success signal: $LASTEXITCODE would otherwise leak from the last
# native call (python/git) and report failure on a passing run.
exit 0
