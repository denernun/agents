<# Read-only diagnostics. Installed files do not prove IDE discovery or approval. #>
[CmdletBinding()]
param(
  [string]$HubPath = (Split-Path -Parent $PSScriptRoot),
  [string[]]$Roots = @(),
  [string[]]$Ides = @('Cursor','Claude','Codex','Antigravity','OpenCode'),
  [switch]$Json
)
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'AgentHub.Common.ps1')
Import-HubFunctions
$cat = Get-Content (Join-Path $HubPath 'catalog/projects.json') -Raw | ConvertFrom-Json
$families = Get-CatalogFamilies -Catalog $cat
if (-not $Roots.Count) { $Roots=@($cat.roots | ForEach-Object { Join-Path 'D:/SISTEMAS' $_ } | Where-Object { Test-Path $_ }) }
$Roots=@($Roots | ForEach-Object {
  $root=$_
  $children=@($cat.roots | ForEach-Object { Join-Path $root $_ } | Where-Object { Test-Path $_ })
  if ($children.Count) { $children } else { $root }
} | Select-Object -Unique)
$map = Get-IdeRegistry
$rows=@()
foreach ($root in $Roots) {
  foreach ($project in Get-ChildItem -LiteralPath $root -Directory) {
    if ($cat.excludeProjectNames -contains $project.Name) { continue }
    if (-not ((Test-Path (Join-Path $project.FullName '.git')) -or (Test-Path (Join-Path $project.FullName 'AGENTS.md')) -or (Test-Path (Join-Path $project.FullName 'package.json')))) { continue }
    $family=Get-ProjectFamily -Name $project.Name -Families $families -RepoPath $project.FullName -Overrides (Get-JsonProperty $cat 'projectFamilies')
    $skills=@(Get-ProjectSkillNames -Catalog $cat -FamilyCfg $families[$family] -Family $family -ProjectName $project.Name)
    $expected=@(Get-ProjectMcpServerNames -ProjectName $project.Name -FamilyCfg $families[$family] -Catalog $cat)
    if (-not (Get-NestSwaggerMcpVars $project.FullName)) { $expected=@($expected | Where-Object { $_ -ne 'openapi' }) }
    foreach ($ide in $Ides) {
      if (-not $map.Contains($ide)) { throw "Unknown IDE: $ide" }
      $entry=$map[$ide]; $missing=@(); $servers=@(); $disabled=@(); $syntax='missing'
      $ideExpected=@($expected | Where-Object {
        $skip=Get-JsonProperty $cat.mcp.skipIdes $_
        @($skip) -notcontains $ide
      })
      foreach ($name in $skills) { if (-not (Test-HubSkill (Join-Path $project.FullName "$($entry.Skills)/$name"))) { $missing += $name } }
      $path=Join-Path $project.FullName $entry.Mcp
      if (Test-Path -LiteralPath $path) {
        try {
          if ($entry.Property -eq 'toml') {
            $request=@{action='inspect-toml';path=$path} | ConvertTo-Json -Compress
            $reply=$request | & (Get-HubPython) (Join-Path $PSScriptRoot 'agenthub_config.py') | ConvertFrom-Json
            if ($LASTEXITCODE -ne 0) { throw 'Invalid TOML' }
            $servers=@($reply.servers); $disabled=@($reply.disabled)
          } else {
            $obj=Get-Content -LiteralPath $path -Raw | ConvertFrom-Json
            $entries=$obj.($entry.Property); $servers=@($entries.PSObject.Properties.Name)
            foreach ($prop in $entries.PSObject.Properties) { if ($prop.Value.disabled -eq $true -or $prop.Value.enabled -eq $false) { $disabled += $prop.Name } }
          }
          $syntax='valid'
        } catch { $syntax='invalid' }
      }
      $rows += [pscustomobject]@{project=$project.Name;family=$family;ide=$ide;missingSkills=$missing;config=$syntax;missingMcp=@($ideExpected | Where-Object { $servers -notcontains $_ });configuredMcp=$servers;disabledInConfig=$disabled;discovery='not observed in IDE';approval='not observed in IDE';connection='not tested'}
    }
  }
}
if ($Json) { $rows | ConvertTo-Json -Depth 8 }
else {
  foreach ($row in $rows) { Write-Output "$($row.project) [$($row.family)] $($row.ide): config=$($row.config); missing skills=$($row.missingSkills.Count); missing MCP=$($row.missingMcp -join ',')" }
  Write-Output 'Discovery, approval and connection require checking the IDE. Cursor: Customize > MCPs; Codex/Claude: /mcp. Reopen the session to refresh skills.'
}
