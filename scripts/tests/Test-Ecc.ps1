$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$source = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
. (Join-Path $source 'scripts/AgentHub.Common.ps1')
Import-HubFunctions
function Assert($condition, $message) { if (-not $condition) { throw $message } }
$cat = Get-Content (Join-Path $source 'catalog/projects.json') -Raw | ConvertFrom-Json
$expected = @('api-design','contract-first','e2e-testing','eval-harness','security-scan','skill-stocktake')
Assert (-not (Compare-Object $expected @($cat.ecc.skills.PSObject.Properties.Name | Sort-Object))) 'ECC selection differs from approved six'
Assert ((@(Get-EccSkillNames $cat -Family nestjs -ProjectName sample-api) | Sort-Object) -join ',' -eq 'api-design,contract-first') 'NestJS scope incorrect'
Assert ((@(Get-EccSkillNames $cat -Family angular -ProjectName sample-admin) | Sort-Object) -join ',' -eq 'contract-first,e2e-testing') 'Angular scope incorrect'
Assert (@(Get-EccSkillNames $cat -Family minimal -ProjectName sample-www) -join ',' -eq 'e2e-testing') 'Site scope incorrect'
Assert (@(Get-EccSkillNames $cat -Family minimal -ProjectName sample-tool).Count -eq 0) 'Generic tools received E2E'
Assert (@(Get-EccSkillNames $cat -Family delphi -ProjectName sample-erp).Count -eq 0) 'Delphi scope changed'
Assert (@(Get-EccSkillNames $cat -Family android -ProjectName mobiclass-apk).Count -eq 0) 'Android scope changed'
Assert (@(Get-EccSkillNames $cat -Maintenance).Count -eq 3) 'Maintenance scope incorrect'
foreach ($name in $expected) {
  Assert (Test-HubSkill (Join-Path $source "skills/$name")) "Invalid metadata: $name"
  Assert (Test-Path (Join-Path $source "skills/$name/LICENSE")) "Missing license: $name"
}
$revision = & git -C (Join-Path $source 'vendor/ecc') rev-parse HEAD
Assert ($LASTEXITCODE -eq 0 -and $revision -eq $cat.ecc.revision) 'ECC vendor revision differs from reviewed source'
$root = Join-Path $source ('.audit-output/ecc-tests-' + [guid]::NewGuid().ToString('N'))
$HubPath = Join-Path $root 'hub'
New-Item -ItemType Directory -Path (Join-Path $HubPath 'skills') -Force | Out-Null
foreach ($name in $expected) { Copy-Item (Join-Path $source "skills/$name") (Join-Path $HubPath 'skills') -Recurse }
$skillRoot = Join-Path $root 'sample-api/.agents/skills'
$names = @(Get-EccSkillNames $cat -Family nestjs -ProjectName sample-api)
Sync-EccSkillLinks -HubPath $HubPath -SkillRoot $skillRoot -Catalog $cat -Names $names -DryRun
Assert (-not (Test-Path $skillRoot)) 'Dry run wrote files'
Sync-EccSkillLinks -HubPath $HubPath -SkillRoot $skillRoot -Catalog $cat -Names $names
$targetBefore = (Get-Item (Join-Path $skillRoot 'api-design')).Target
Sync-EccSkillLinks -HubPath $HubPath -SkillRoot $skillRoot -Catalog $cat -Names $names
Assert ((Get-Item (Join-Path $skillRoot 'api-design')).Target -eq $targetBefore) 'Repeated sync changed target'
$manual = Join-Path $skillRoot 'e2e-testing'
New-Item -ItemType Directory -Path $manual | Out-Null
Set-Content (Join-Path $manual 'SKILL.md') 'Manual skill preserved'
Sync-EccSkillLinks -HubPath $HubPath -SkillRoot $skillRoot -Catalog $cat -Names @('e2e-testing')
Assert ((Get-Content (Join-Path $manual 'SKILL.md')) -eq 'Manual skill preserved') 'Manual collision overwritten'
Assert (-not (Test-Path (Join-Path $skillRoot 'api-design'))) 'Removed scope remained linked'
Assert (Test-Path (Join-Path $HubPath 'skills/api-design/SKILL.md')) 'Unlink deleted source'
Sync-EccSkillLinks -HubPath $HubPath -SkillRoot $skillRoot -Catalog $cat -Names @()
Assert (Test-Path $manual) 'Manual skill removed'
# Real junctions deduplicate aliases in the portable inventory.
$aliases = Join-Path $root 'aliases'
New-Item -ItemType Directory $aliases | Out-Null
New-Item -ItemType Junction -Path (Join-Path $aliases 'api-alias') -Target (Join-Path $HubPath 'skills/api-design') | Out-Null
$snapshot = Join-Path $root 'snapshot.json'
& (Get-HubPython) (Join-Path $source 'skills/skill-stocktake/scripts/stocktake.py') --hub $HubPath --root $aliases --output $snapshot
Assert ($LASTEXITCODE -eq 0) 'Portable inventory failed'
$inventory = Get-Content $snapshot -Raw | ConvertFrom-Json
Assert ($inventory.skills.Count -eq 6) 'Junction counted as separate skill'
Assert (@($inventory.skills | Where-Object name -eq 'api-design')[0].aliases.Count -eq 2) 'Alias lost'
$scan = & (Join-Path $source 'skills/security-scan/scripts/scan.ps1') -Path $root -DryRun | ConvertFrom-Json
Assert ($scan.package -eq 'ecc-agentshield@1.6.0' -and -not $scan.mutates) 'Scanner is unpinned or mutating'
$gateOutput = & node (Join-Path $source 'vendor/ecc/scripts/eval-harness.js') gate run missing.json 2>&1
Assert ($LASTEXITCODE -eq 1 -and "$gateOutput" -match 'gate.isolation_required') 'ECC execution refusal was not preserved'
Write-Host 'ECC integration checks passed'

# Explicit success signal: $LASTEXITCODE would otherwise leak from the last
# native call (python/git) and report failure on a passing run.
exit 0
