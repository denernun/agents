<# Read-only verification of ECC links and payloads; does not infer IDE discovery. #>
[CmdletBinding()]
param([string]$HubPath = (Split-Path -Parent $PSScriptRoot), [switch]$GlobalSkills)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'AgentHub.Common.ps1')
Import-HubFunctions
[void](Import-HubDotEnv $HubPath)
$cat = Get-Content (Join-Path $HubPath 'catalog/projects.json') -Raw | ConvertFrom-Json
$policy = Resolve-IdePolicy $cat
$ides = Get-DetectedIdes -Allowed @($policy.Allowed) -Excluded @($policy.Excluded)
$paths = @{Cursor='.cursor/skills'; Claude='.claude/skills'; Codex='.agents/skills'; Antigravity='.agents/skills'; OpenCode='.opencode/skills'; VSCode='.github/skills'; Kiro='.kiro/skills'; Devin='.devin/skills'}
$relPaths = @($ides | ForEach-Object { $paths[$_] } | Select-Object -Unique)
$families = @{}; foreach ($p in $cat.families.PSObject.Properties) { $families[$p.Name]=$p.Value }
$script:checked = 0
$script:failures = @()
function Check-Scope([string]$Root, [string[]]$Names) {
  foreach ($skill in $cat.ecc.skills.PSObject.Properties.Name) {
    $path = Join-Path $Root $skill
    if ($Names -contains $skill) {
      $source = Join-Path $HubPath "skills/$skill/SKILL.md"
      $file = Join-Path $path 'SKILL.md'
      if (-not (Test-HubSkill $path)) { $script:failures += "Missing/invalid: $path"; continue }
      if ((Get-FileHash $source).Hash -ne (Get-FileHash $file).Hash) { $script:failures += "Different content: $path"; continue }
      if (-not (Test-HubOwnedLink -Path $path -HubPath $HubPath)) { $script:failures += "Unmanaged collision: $path"; continue }
      $script:checked++
    } elseif (Test-HubOwnedLink -Path $path -HubPath $HubPath) {
      $script:failures += "Unexpected ECC scope: $path"
    }
  }
}
$maintenance = @(Get-EccSkillNames $cat -Maintenance)
foreach ($rel in $relPaths) { Check-Scope (Join-Path $HubPath $rel) $maintenance }
if ($GlobalSkills -and $ides -contains 'Codex') { Check-Scope (Join-Path $env:USERPROFILE '.agents/skills') $maintenance }
$projects = 0
foreach ($name in $cat.roots) {
  $root = Join-Path 'D:/SISTEMAS' $name
  if (-not (Test-Path $root)) { continue }
  foreach ($project in Get-ChildItem $root -Directory) {
    if ($cat.excludeProjectNames -contains $project.Name) { continue }
    if (-not ((Test-Path (Join-Path $project.FullName '.git')) -or (Test-Path (Join-Path $project.FullName 'AGENTS.md')) -or (Test-Path (Join-Path $project.FullName 'package.json')))) { continue }
    $family = Get-ProjectFamily -Name $project.Name -Families $families -RepoPath $project.FullName -Overrides $cat.projectFamilies
    $names = @(Get-EccSkillNames $cat -Family $family -ProjectName $project.Name)
    foreach ($rel in $relPaths) { Check-Scope (Join-Path $project.FullName $rel) $names }
    $projects++
  }
}
if ($failures.Count) { $failures | Write-Output; throw 'ECC installed verification failed' }
Write-Output "ECC installed verification passed: $projects projects; $checked skill links; no scope/content errors. IDE discovery not observed."
