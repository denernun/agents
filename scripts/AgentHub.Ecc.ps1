# ECC adapters are tracked hub skills, not mirrors of the entire ECC plugin.
function Get-EccSkillNames {
  param([object]$Catalog, [string]$Family, [string]$ProjectName, [switch]$Maintenance)
  $entry = $Catalog.PSObject.Properties['ecc']
  if (-not $entry) { return }
  foreach ($skill in $entry.Value.skills.PSObject.Properties) {
    $cfg = $skill.Value
    if ($Maintenance) {
      if ($cfg.maintenance) { $skill.Name }
    } elseif (($cfg.families -contains $Family) -or @($cfg.match | Where-Object { $ProjectName -like $_ }).Count) {
      $skill.Name
    }
  }
}

function Sync-EccSkillLinks {
  # Touch only ECC names; preserve unrelated hub and manual skills on targeted sync.
  param([string]$HubPath, [string]$SkillRoot, [object]$Catalog, [string[]]$Names, [switch]$DryRun)
  foreach ($skill in $Catalog.ecc.skills.PSObject.Properties) {
    $target = Join-Path $HubPath "skills/$($skill.Name)"
    $link = Join-Path $SkillRoot $skill.Name
    if ($Names -contains $skill.Name) {
      if (-not (Test-HubSkill $target)) { throw "Invalid ECC adapter: $target" }
      New-JunctionOrCopy -LinkPath $link -TargetPath $target -DryRun:$DryRun
    } else {
      Remove-HubLink -Path $link -Root $SkillRoot -HubPath $HubPath -DryRun:$DryRun
    }
  }
}
