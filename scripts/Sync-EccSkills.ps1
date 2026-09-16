<# Skills-only ECC distribution. No MCP, hooks, vendor updates or product configuration changes. #>
[CmdletBinding()]
param(
  [string]$HubPath = (Split-Path -Parent $PSScriptRoot),
  [string[]]$Roots = @(),
  [string[]]$Ides = @(),
  [switch]$GlobalSkills,
  [switch]$DryRun
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'AgentHub.Common.ps1')
Import-HubFunctions
$cat = Get-Content (Join-Path $HubPath 'catalog/projects.json') -Raw | ConvertFrom-Json
$families = @{}; foreach ($p in $cat.families.PSObject.Properties) { $families[$p.Name] = $p.Value }
[void](Import-HubDotEnv -HubPath $HubPath)
$policy = Resolve-IdePolicy -Catalog $cat
$Ides = Get-DetectedIdes -Override $Ides -Allowed @($policy.Allowed) -Excluded @($policy.Excluded)
$paths = @{ Cursor='.cursor/skills'; Claude='.claude/skills'; Codex='.agents/skills'; Antigravity='.agents/skills'; OpenCode='.opencode/skills'; VSCode='.github/skills'; Kiro='.kiro/skills'; Devin='.devin/skills' }
foreach ($ide in $Ides) { if (-not $paths.ContainsKey($ide)) { throw "Unknown IDE: $ide" } }
if (-not $Roots.Count) { $Roots = @($cat.roots | ForEach-Object { Join-Path 'D:/SISTEMAS' $_ } | Where-Object { Test-Path $_ }) }
$rootsResolved = @($Roots | ForEach-Object {
  $root = $_
  $children = @($cat.roots | ForEach-Object { Join-Path $root $_ } | Where-Object { Test-Path $_ })
  if ($children.Count) { $children } else { $root }
} | Select-Object -Unique)
# Preflight every selected source before the first link.
foreach ($p in $cat.ecc.skills.PSObject.Properties) {
  if (-not (Test-HubSkill (Join-Path $HubPath "skills/$($p.Name)"))) { throw "Invalid ECC skill: $($p.Name)" }
}
$maintenance = @(Get-EccSkillNames -Catalog $cat -Maintenance)
foreach ($rel in @($Ides | ForEach-Object { $paths[$_] } | Select-Object -Unique)) {
  Sync-EccSkillLinks -HubPath $HubPath -SkillRoot (Join-Path $HubPath $rel) -Catalog $cat -Names $maintenance -DryRun:$DryRun
}
if ($GlobalSkills -and $Ides -contains 'Codex') {
  Sync-EccSkillLinks -HubPath $HubPath -SkillRoot (Join-Path $env:USERPROFILE '.agents/skills') -Catalog $cat -Names $maintenance -DryRun:$DryRun
}
$count = 0
foreach ($root in $rootsResolved) {
  foreach ($project in Get-ChildItem -LiteralPath $root -Directory) {
    if ($cat.excludeProjectNames -contains $project.Name) { continue }
    if (-not ((Test-Path (Join-Path $project.FullName '.git')) -or (Test-Path (Join-Path $project.FullName 'AGENTS.md')) -or (Test-Path (Join-Path $project.FullName 'package.json')))) { continue }
    $family = Get-ProjectFamily -Name $project.Name -Families $families -RepoPath $project.FullName -Overrides $cat.projectFamilies
    $names = @(Get-EccSkillNames -Catalog $cat -Family $family -ProjectName $project.Name)
    foreach ($rel in @($Ides | ForEach-Object { $paths[$_] } | Select-Object -Unique)) {
      Sync-EccSkillLinks -HubPath $HubPath -SkillRoot (Join-Path $project.FullName $rel) -Catalog $cat -Names $names -DryRun:$DryRun
    }
    $count++
  }
}
Write-Host "ECC skills sync complete: $count projects inspected. DryRun=$([bool]$DryRun)"
