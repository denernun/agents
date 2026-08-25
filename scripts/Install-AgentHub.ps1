<#
.SYNOPSIS
  Links D:\AGENTS skills into ERPCLASS / NFECLASS / MOBICLASS / SHOPCLASS repos (D:\SISTEMAS).

.DESCRIPTION
  - Detects installed IDEs (Cursor, VS Code, Kiro, OpenCode, Antigravity, Claude Code, Codex, Devin)
  - Creates junctions from hub skills into each project
  - Writes slim AGENTS.md (preserves ## Local section)
  - Generates MCP configs only for detected IDEs (common trio everywhere;
    mongodb + openapi on NestJS APIs that already have Swagger
    (mongodb is node + global mongodb-mcp-server@2, never npx on Windows);
    playwright on Angular/www/ajuda frontends;
    Android family uses the common MCPs only)
  - Optionally removes unused IDE folders (.qoder, .codebuddy)
  - Runs "codegraph init <path>" for projects using the codegraph skill
    that don't have a ".codegraph" folder yet (skip with -SkipCodegraphInit).
    Assumes the codegraph binary is already installed and on PATH (npm i -g
    @colbymchenry/codegraph, or the official installer) — unlike the old
    code-review-graph MCP, codegraph is a self-contained native binary with
    no per-hub Python venv to manage. Does NOT run "codegraph install": that
    CLI subcommand overwrites the merged mcp.json files this script writes.

.EXAMPLE
  .\Install-AgentHub.ps1 -RemoveUnusedIdeFolders -WriteAgents

.EXAMPLE
  .\Install-AgentHub.ps1 -Ides Cursor,VSCode,Kiro -DryRun

.EXAMPLE
  # One-time cleanup of paths written by older script versions
  # (.antigravity\mcp.json, .opencode\opencode.json, .gemini\GEMINI.md)
  .\Install-AgentHub.ps1 -MigrateLegacyPaths -WriteAgents
#>
[CmdletBinding()]
param(
  [string]$HubPath = '',
  [string[]]$Roots = @(),
  [string[]]$Ides = @(),
  [switch]$RemoveUnusedIdeFolders,
  [switch]$WriteAgents,
  [switch]$DryRun,
  [switch]$IncludeQoder,
  [switch]$ForceAgents,
  [switch]$MigrateLegacyPaths,
  [switch]$SkipCodegraphInit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-HubPath {
  param([string]$Path)
  if ($Path) { return (Resolve-Path $Path).Path }
  $scriptDir = Split-Path -Parent $PSScriptRoot
  if (Test-Path (Join-Path $scriptDir 'skills')) { return $scriptDir }
  $default = 'D:\AGENTS'
  if (Test-Path $default) { return $default }
  throw "Hub not found. Pass -HubPath."
}

function Get-DetectedIdes {
  param([string[]]$Override, [string[]]$Allowed, [switch]$IncludeQoder)
  if ($Override -and $Override.Count -gt 0) {
    $candidates = @($Override | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($Allowed -and $Allowed.Count -gt 0) {
      $candidates = @($candidates | Where-Object { $Allowed -contains $_ })
    }
    return , $candidates
  }
  $userHome = $env:USERPROFILE
  $found = [System.Collections.Generic.List[string]]::new()
  if (Test-Path (Join-Path $userHome '.cursor')) { [void]$found.Add('Cursor') }
  if ((Test-Path (Join-Path $userHome '.vscode')) -or (Get-Command code -ErrorAction SilentlyContinue)) {
    [void]$found.Add('VSCode')
  }
  if (Test-Path (Join-Path $userHome '.kiro')) { [void]$found.Add('Kiro') }
  if ((Test-Path (Join-Path $userHome '.antigravity')) -or
      (Test-Path (Join-Path $env:APPDATA 'Antigravity')) -or
      (Test-Path (Join-Path $userHome '.gemini'))) {
    [void]$found.Add('Antigravity')
  }
  if ($IncludeQoder -and (Test-Path (Join-Path $userHome '.qoder'))) { [void]$found.Add('Qoder') }
  if ((Test-Path (Join-Path $userHome '.config\opencode\opencode.json')) -or
      (Test-Path (Join-Path $userHome '.opencode')) -or
      (Get-Command opencode -ErrorAction SilentlyContinue)) {
    [void]$found.Add('OpenCode')
  }
  if ((Test-Path (Join-Path $userHome '.claude')) -or
      (Get-Command claude -ErrorAction SilentlyContinue)) {
    [void]$found.Add('Claude')
  }
  if ((Test-Path (Join-Path $userHome '.codex')) -or
      (Get-Command codex -ErrorAction SilentlyContinue)) {
    [void]$found.Add('Codex')
  }
  if ((Test-Path (Join-Path $userHome '.devin')) -or
      (Test-Path (Join-Path $env:APPDATA 'devin')) -or
      (Get-Command devin -ErrorAction SilentlyContinue)) {
    [void]$found.Add('Devin')
  }
  $candidates = @($found | Select-Object -Unique)
  if ($Allowed -and $Allowed.Count -gt 0) {
    $candidates = @($candidates | Where-Object { $Allowed -contains $_ })
  }
  return , $candidates
}

function Ensure-VendorAgentSkills {
  # Clone or init the addyosmani/agent-skills submodule used by commonSkills.
  param([string]$HubPath, [switch]$DryRun)
  $vendor = Join-Path $HubPath 'vendor\addyosmani-agent-skills'
  $url = 'https://github.com/addyosmani/agent-skills.git'
  if (Test-Path (Join-Path $vendor 'skills')) { return $vendor }
  if ($DryRun) {
    Write-Host "  [dry] clone $url -> $vendor"
    return $vendor
  }
  $parent = Split-Path -Parent $vendor
  if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  Push-Location $HubPath
  try {
    if (Test-Path (Join-Path $HubPath '.gitmodules')) {
      git submodule update --init --recursive -- vendor/addyosmani-agent-skills 2>$null | Out-Null
    }
  } finally {
    Pop-Location
  }
  if (-not (Test-Path (Join-Path $vendor 'skills'))) {
    Write-Host "Cloning $url -> $vendor"
    git clone --depth 1 $url $vendor
  }
  # Validate that the vendor skills are actually available after all attempts
  if (-not (Test-Path (Join-Path $vendor 'skills'))) {
    Write-Warning "Vendor skills unavailable: git submodule/clone failed for $url. Vendor-based skills will be skipped."
    return $null
  }
  return $vendor
}

function Ensure-VendorSkillMirrors {
  # Junctions from hub skills/ + references/ into the vendor clone.
  # These paths are gitignored; this function is what makes a fresh clone usable.
  param([string]$HubPath, [string[]]$SkillNames, [switch]$DryRun)
  if (-not $SkillNames -or $SkillNames.Count -eq 0) { return }
  $vendor = Ensure-VendorAgentSkills -HubPath $HubPath -DryRun:$DryRun
  if (-not $vendor) { return }
  foreach ($name in $SkillNames) {
    $target = Join-Path $vendor "skills\$name"
    if (-not (Test-Path $target)) {
      Write-Warning "Vendor skill missing: $target"
      continue
    }
    New-JunctionOrCopy -LinkPath (Join-Path $HubPath "skills\$name") -TargetPath $target -DryRun:$DryRun
  }
  $refTarget = Join-Path $vendor 'references'
  if (Test-Path $refTarget) {
    New-JunctionOrCopy -LinkPath (Join-Path $HubPath 'references') -TargetPath $refTarget -DryRun:$DryRun
  }
}

function Ensure-VendorStandaloneSkill {
  # Clone or init a vendor skill whose SKILL.md lives at the vendor root
  # (not under vendor/skills/<name>). Junctions hub skills/<name> -> vendor.
  param(
    [string]$HubPath,
    [string]$SkillName,
    [string]$VendorRelativePath,
    [string]$Url,
    [switch]$DryRun
  )
  $vendor = Join-Path $HubPath ($VendorRelativePath -replace '/', '\')
  $skillMd = Join-Path $vendor 'SKILL.md'
  if (-not (Test-Path $skillMd)) {
    if ($DryRun) {
      Write-Host "  [dry] clone $Url -> $vendor"
    } else {
      $parent = Split-Path -Parent $vendor
      if (-not (Test-Path $parent)) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
      Push-Location $HubPath
      try {
        if (Test-Path (Join-Path $HubPath '.gitmodules')) {
          git submodule update --init --recursive -- $VendorRelativePath 2>$null | Out-Null
        }
      } finally {
        Pop-Location
      }
      if (-not (Test-Path $skillMd)) {
        Write-Host "Cloning $Url -> $vendor"
        git clone --depth 1 $Url $vendor
      }
    }
  }
  if (-not (Test-Path $skillMd)) {
    Write-Warning "Standalone vendor skill unavailable: $Url ($VendorRelativePath)"
    return
  }
  New-JunctionOrCopy -LinkPath (Join-Path $HubPath "skills\$SkillName") -TargetPath $vendor -DryRun:$DryRun
}

function Get-ProjectFamily {
  param([string]$Name, [hashtable]$Families)
  $order = @('nestjs', 'angular', 'delphi', 'android')
  foreach ($key in $order) {
    if (-not $Families.ContainsKey($key)) { continue }
    foreach ($pattern in $Families[$key].match) {
      if ($Name -like $pattern) { return $key }
    }
  }
  return 'minimal'
}

function Test-SkillTargetHasContent {
  # Guards against silently linking an empty/corrupted skill directory into
  # every project. A skill target is a directory that should contain at
  # least one non-empty file (normally SKILL.md); "references" is a plain
  # folder of checklists, not a single skill, so any non-empty file counts.
  # A directory containing only a ".gitkeep" placeholder (e.g. an
  # intentionally-empty skill stub like delphi-erpclass) is treated as valid.
  param([string]$TargetPath)
  if (-not (Test-Path $TargetPath -PathType Container)) { return $true } # not a dir mirror case, let caller handle
  $files = @(Get-ChildItem -Path $TargetPath -Recurse -File -Force -ErrorAction SilentlyContinue)
  if ($files.Count -eq 0) { return $false }
  $realFiles = @($files | Where-Object { $_.Name -ne '.gitkeep' })
  if ($realFiles.Count -eq 0) { return $true } # placeholder-only stub, intentional
  $totalBytes = ($realFiles | Measure-Object -Property Length -Sum).Sum
  return ($totalBytes -gt 0)
}

function New-JunctionOrCopy {
  param([string]$LinkPath, [string]$TargetPath, [switch]$DryRun)
  if (-not (Test-Path $TargetPath)) {
    Write-Warning "Missing skill target: $TargetPath"
    return
  }
  if ((Test-Path $TargetPath -PathType Container) -and -not (Test-SkillTargetHasContent -TargetPath $TargetPath)) {
    Write-Warning "Skill target is empty (0 bytes of content): $TargetPath -- refusing to link $LinkPath. Fix the source (e.g. 'git checkout -- <path>' in the hub or vendor submodule) and re-run."
    return
  }
  $parent = Split-Path -Parent $LinkPath
  if (-not (Test-Path $parent)) {
    if (-not $DryRun) { New-Item -ItemType Directory -Force -Path $parent | Out-Null }
  }
  if (Test-Path $LinkPath) {
    $item = Get-Item $LinkPath -Force
    $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
    if ($isReparse) {
      if (-not $DryRun) {
        cmd /c "rmdir `"$LinkPath`"" | Out-Null
        if (Test-Path $LinkPath) {
          Write-Warning "Failed to remove existing junction at $LinkPath - skipping."
          return
        }
      }
    } else {
      # Real directory (not a junction). Only remove if it contains the
      # .agenthub-managed marker written by a previous Copy fallback.
      $markerPath = Join-Path $LinkPath '.agenthub-managed'
      if (-not (Test-Path $markerPath)) {
        Write-Warning "Existing directory at $LinkPath is not hub-managed (no .agenthub-managed marker). Skipping to avoid data loss. Remove manually if unneeded."
        return
      }
      if (-not $DryRun) { Remove-Item $LinkPath -Recurse -Force }
    }
  }
  if ($DryRun) {
    Write-Host "  [dry] junction $LinkPath -> $TargetPath"
    return
  }
  $ok = $true
  cmd /c "mklink /J `"$LinkPath`" `"$TargetPath`"" | Out-Null
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "Junction failed for $LinkPath - copying instead."
    Copy-Item $TargetPath $LinkPath -Recurse -Force
    # Write marker so future runs know this copy belongs to the hub
    Set-Content -Path (Join-Path $LinkPath '.agenthub-managed') -Value "Created by Install-AgentHub.ps1 on $(Get-Date -Format 'yyyy-MM-dd HH:mm'). Safe to delete this folder." -Encoding UTF8
    $ok = $false
  }
  if ($ok) { Write-Host "  linked $LinkPath" }
}

function Ensure-CodegraphInit {
  # Runs "codegraph init <path>" for projects that use the codegraph skill
  # and don't have an index yet. Deliberately does NOT call "codegraph
  # install" here: that CLI command auto-configures editor MCP configs
  # directly, overwriting the family-scoped MCP set that Write-McpConfigs
  # already wrote.
  param(
    [string]$RepoPath,
    [string[]]$Skills,
    [switch]$Force,
    [switch]$DryRun
  )
  if ($Skills -notcontains 'codegraph') { return }
  $graphDir = Join-Path $RepoPath '.codegraph'
  if ((Test-Path $graphDir) -and -not $Force) { return }
  if ($DryRun) {
    Write-Host "  [dry] codegraph init `"$RepoPath`""
    return
  }
  if (-not (Get-Command codegraph -ErrorAction SilentlyContinue)) {
    Write-Warning "  codegraph not found on PATH; skipping index init for $RepoPath (npm i -g @colbymchenry/codegraph)"
    return
  }
  Write-Host "  initializing codegraph index for $RepoPath ..."
  & codegraph init $RepoPath
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "  codegraph init failed for $RepoPath (exit $LASTEXITCODE)"
    return
  }
  $gitignore = Join-Path $RepoPath '.gitignore'
  $entry = '.codegraph/'
  if (Test-Path $gitignore) {
    $lines = Get-Content $gitignore -Encoding UTF8
    if ($lines -notcontains $entry) {
      Add-Content -Path $gitignore -Value $entry -Encoding UTF8
    }
  } else {
    Set-Content -Path $gitignore -Value $entry -Encoding UTF8
  }
}

function Get-LocalSection {
  param([string]$Path)
  if (-not (Test-Path $Path)) { return $null }
  $raw = Get-Content $Path -Raw -Encoding UTF8
  $idx = $raw.IndexOf("## Local")
  if ($idx -lt 0) { return $null }
  return $raw.Substring($idx).TrimEnd()
}

function Write-AgentsFile {
  param(
    [string]$RepoPath,
    [string]$ProjectName,
    [string]$TemplatePath,
    [switch]$Force,
    [switch]$DryRun
  )
  $dest = Join-Path $RepoPath 'AGENTS.md'
  $local = $null
  if ((Test-Path $dest) -and -not $Force) {
    $local = Get-LocalSection -Path $dest
  }
  $content = (Get-Content $TemplatePath -Raw -Encoding UTF8).Replace('{{PROJECT}}', $ProjectName)
  if ($local) {
    # drop template Local and append preserved
    $content = [regex]::Replace($content, '(?s)## Local\s*\r?\n.*$', '').TrimEnd() + "`r`n`r`n" + $local + "`r`n"
  }
  if ($DryRun) {
    $kb = [math]::Round($content.Length / 1KB, 1)
    Write-Host ('  [dry] write AGENTS.md sizeKb=' + $kb)
    return
  }
  Set-Content -Path $dest -Value $content -Encoding UTF8
  Write-Host "  wrote AGENTS.md"
}

function ConvertTo-TomlBasicString {
  param([string]$Value)
  return $Value.Replace('\', '\\').Replace('"', '\"')
}

function Get-NpmGlobalRoot {
  if (-not (Get-Command npm -ErrorAction SilentlyContinue)) { return $null }
  $root = (& npm root -g 2>$null | Select-Object -Last 1)
  if ([string]::IsNullOrWhiteSpace($root)) { return $null }
  return $root.Trim()
}

function Find-MongodbMcpEntry {
  param([string]$GlobalRoot)
  if (-not $GlobalRoot) { return $null }
  foreach ($rel in @(
      'mongodb-mcp-server\dist\esm\index.js',
      'mongodb-mcp-server\dist\index.js'
    )) {
    $p = Join-Path $GlobalRoot $rel
    if (Test-Path -LiteralPath $p) { return (Resolve-Path -LiteralPath $p).Path }
  }
  return $null
}

function Resolve-MongodbMcpLaunch {
  # Direct node + global package entry. Do not use `cmd /c npx` on Windows:
  # Cursor/VS Code leaving that chain orphaned accumulates zombie
  # node/cmd/conhost processes and can freeze the IDE.
  #
  # npm writes to the success stream; capture it. Otherwise (with
  # Set-StrictMode) the caller sees an Object[] and `.Node` throws
  # "The property 'Node' cannot be found on this object".
  param([switch]$DryRun)
  $nodeCmd = Get-Command node -ErrorAction SilentlyContinue
  if (-not $nodeCmd) {
    Write-Warning 'node not on PATH; skipping mongodb MCP (no npx fallback — it orphans processes on Windows).'
    return $null
  }
  $nodeExe = $nodeCmd.Source
  $globalRoot = Get-NpmGlobalRoot
  $entry = Find-MongodbMcpEntry -GlobalRoot $globalRoot
  if (-not $entry) {
    if ($DryRun) {
      Write-Host '  [dry] npm i -g mongodb-mcp-server@2'
      return $null
    }
    Write-Host 'Installing mongodb-mcp-server@2 globally (node launch, no npx)...'
    $npmOut = & npm i -g mongodb-mcp-server@2 2>&1
    $npmCode = $LASTEXITCODE
    foreach ($line in @($npmOut)) { Write-Host $line }
    if ($npmCode -ne 0) {
      Write-Warning 'npm i -g mongodb-mcp-server@2 failed; skipping mongodb MCP.'
      return $null
    }
    $globalRoot = Get-NpmGlobalRoot
    $entry = Find-MongodbMcpEntry -GlobalRoot $globalRoot
  }
  if (-not $entry) {
    Write-Warning "mongodb-mcp-server entry script not found under $globalRoot"
    return $null
  }
  Write-Host "MongoDB MCP: $nodeExe $entry"
  return [pscustomobject]@{ Node = $nodeExe; Entry = $entry }
}

function Warn-GlobalCursorMongodbDuplicate {
  $path = Join-Path $env:USERPROFILE '.cursor\mcp.json'
  if (-not (Test-Path -LiteralPath $path)) { return }
  try {
    $obj = Get-Content -LiteralPath $path -Raw -Encoding UTF8 | ConvertFrom-Json
    $names = @()
    if ($obj.mcpServers) { $names = @($obj.mcpServers.PSObject.Properties.Name) }
    if ($names -contains 'mongodb') {
      Write-Warning 'Global ~/.cursor/mcp.json also defines mongodb. Hub writes it per NestJS project — disable the global server to avoid a second process in every Cursor window.'
    }
  } catch {
    # ignore unreadable global config
  }
}

function Expand-McpTemplate {
  param([string]$Content, [hashtable]$Vars, [switch]$JsonEscape)
  foreach ($k in $Vars.Keys) {
    $val = $Vars[$k]
    # Converter barras invertidas para barras normais em caminhos Windows (para TOML)
    if ($val -match '^[A-Z]:\\') {
      $val = $val.Replace('\', '/')
    }
    if ($JsonEscape) { $val = $val.Replace('\', '\\').Replace('"', '\"') }
    $Content = $Content.Replace("{{$k}}", $val)
  }
  return $Content
}

function Get-JsonProperty {
  param([object]$Object, [string]$Name)
  if (-not $Object) { return $null }
  $prop = $Object.PSObject.Properties[$Name]
  if (-not $prop) { return $null }
  return $prop.Value
}

function Get-NestSwaggerMcpVars {
  # Only when src/main.ts actually sets up Swagger. Live spec URL is used;
  # the MCP needs the API running. toolsMode=dynamic keeps 3 meta-tools.
  param([string]$RepoPath)
  $main = Join-Path $RepoPath 'src\main.ts'
  if (-not (Test-Path $main)) { return $null }
  $text = Get-Content $main -Raw -Encoding UTF8
  if ($text -notmatch 'SwaggerModule') { return $null }

  $port = $null
  $cfgPath = Join-Path $RepoPath 'src\config\.development.json'
  if (Test-Path $cfgPath) {
    try {
      $cfg = Get-Content $cfgPath -Raw -Encoding UTF8 | ConvertFrom-Json
      $auth = Get-JsonProperty -Object $cfg -Name 'auth'
      $api = Get-JsonProperty -Object $cfg -Name 'api'
      $authPort = Get-JsonProperty -Object $auth -Name 'port'
      $apiPort = Get-JsonProperty -Object $api -Name 'port'
      $rootPort = Get-JsonProperty -Object $cfg -Name 'port'
      if ($RepoPath -match '[\\/][^-\\/]+-auth$' -and $authPort) { $port = [int]$authPort }
      elseif ($apiPort) { $port = [int]$apiPort }
      elseif ($authPort) { $port = [int]$authPort }
      elseif ($rootPort) { $port = [int]$rootPort }
    } catch {
      Write-Warning "Could not parse $cfgPath for OpenAPI MCP port: $_"
    }
  }
  if (-not $port) { $port = 3000 }

  $scheme = 'http'
  if ($text -match 'httpsOptions') { $scheme = 'https' }
  $base = "${scheme}://localhost:$port"

  $specRel = 'docs-json'
  if ($text -match "jsonDocumentUrl:\s*'([^']+)'") {
    $specRel = $Matches[1].TrimStart('/')
  } elseif ($text -match "SwaggerModule\.setup\(\s*'([^']+)'") {
    $specRel = "$($Matches[1])-json"
  }

  return @{
    API_BASE_URL = $base
    OPENAPI_SPEC_PATH = "$base/$specRel"
  }
}

function Get-CatalogMcpCommon {
  param([object]$Catalog)
  if ($Catalog.mcp -and $Catalog.mcp.common) {
    return @($Catalog.mcp.common)
  }
  return @('context7', 'filesystem')
}

function Get-ManagedMcpServerNames {
  param([object]$Catalog, [hashtable]$Families)
  $names = [System.Collections.Generic.List[string]]::new()
  foreach ($s in (Get-CatalogMcpCommon -Catalog $Catalog)) { [void]$names.Add($s) }
  foreach ($family in $Families.Values) {
    foreach ($s in @($family.mcp)) {
      if ($s -and $names -notcontains $s) { [void]$names.Add($s) }
    }
  }
  if ($Catalog.mcp -and $Catalog.mcp.extra) {
    foreach ($extra in @($Catalog.mcp.extra)) {
      foreach ($s in @($extra.servers)) {
        if ($s -and $names -notcontains $s) { [void]$names.Add($s) }
      }
    }
  }
  return @($names)
}

function Get-ProjectMcpServerNames {
  param(
    [string]$ProjectName,
    [object]$FamilyCfg,
    [object]$Catalog
  )
  $names = [System.Collections.Generic.List[string]]::new()
  foreach ($s in (Get-CatalogMcpCommon -Catalog $Catalog)) { [void]$names.Add($s) }
  foreach ($s in @($FamilyCfg.mcp)) {
    if ($s -and $names -notcontains $s) { [void]$names.Add($s) }
  }
  if ($Catalog.mcp -and $Catalog.mcp.extra) {
    foreach ($extra in @($Catalog.mcp.extra)) {
      $matched = $false
      foreach ($pattern in @($extra.match)) {
        if ($ProjectName -like $pattern) { $matched = $true; break }
      }
      if (-not $matched) { continue }
      foreach ($s in @($extra.servers)) {
        if ($s -and $names -notcontains $s) { [void]$names.Add($s) }
      }
    }
  }
  return @($names)
}

function Select-McpServersForIde {
  param($Servers, [string]$Ide, [object]$SkipIdes)
  $out = [ordered]@{}
  foreach ($name in @($Servers.Keys)) {
    $skipFor = @()
    if ($SkipIdes) {
      $skipPropNames = @($SkipIdes.PSObject.Properties | ForEach-Object { $_.Name })
      if ($skipPropNames -contains $name) {
        $skipFor = @($SkipIdes.$name)
      }
    }
    if ($skipFor -contains $Ide) { continue }
    $out[$name] = $Servers[$name]
  }
  return $out
}

function Merge-McpJsonTemplates {
  param([string]$HubPath, [hashtable]$Vars, [string[]]$ServerNames)
  $merged = [ordered]@{}
  foreach ($name in $ServerNames) {
    $path = Join-Path $HubPath "mcp\$name.template.json"
    if (-not (Test-Path $path)) {
      Write-Warning "Missing MCP template: $path"
      continue
    }
    $raw = Get-Content $path -Raw -Encoding UTF8
    $expanded = Expand-McpTemplate -Content $raw -Vars $Vars -JsonEscape
    try {
      $obj = $expanded | ConvertFrom-Json
    } catch {
      throw "Failed to parse MCP template $name.template.json: $_`n$expanded"
    }
    foreach ($prop in $obj.mcpServers.PSObject.Properties) {
      $merged[$prop.Name] = $prop.Value
    }
  }
  return $merged
}

function ConvertTo-TomlMcp {
  param([System.Collections.IDictionary]$Servers, [string[]]$SkipProperties = @())
  $skip = @($SkipProperties) + @('env')
  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($name in $Servers.Keys | Sort-Object) {
    [void]$lines.Add("[mcp_servers.$name]")
    $server = $Servers[$name]
    foreach ($prop in $server.PSObject.Properties | Sort-Object Name) {
      if ($skip -contains $prop.Name) { continue }
      $val = $prop.Value
      if ($val -is [array] -or ($val -is [System.Collections.IEnumerable] -and $val -isnot [string])) {
        $parts = @($val | ForEach-Object { "`"$(ConvertTo-TomlBasicString $_)`"" })
        [void]$lines.Add("$($prop.Name) = [$($parts -join ', ')]")
      } else {
        [void]$lines.Add("$($prop.Name) = `"$(ConvertTo-TomlBasicString $val)`"")
      }
    }
    $envProp = $server.PSObject.Properties['env']
    if ($envProp -and $envProp.Value) {
      [void]$lines.Add('')
      [void]$lines.Add("[mcp_servers.$name.env]")
      foreach ($e in $envProp.Value.PSObject.Properties | Sort-Object Name) {
        [void]$lines.Add("$($e.Name) = `"$(ConvertTo-TomlBasicString ([string]$e.Value))`"")
      }
    }
    [void]$lines.Add('')
  }
  return ($lines -join "`r`n").TrimEnd()
}

function ConvertTo-OpenCodeMcpServers {
  # OpenCode's schema (https://opencode.ai/docs/mcp-servers) puts servers
  # directly under the top-level "mcp" key (no nested "servers" wrapper).
  param([System.Collections.IDictionary]$Servers)
  $ocServers = [ordered]@{}
  foreach ($name in $Servers.Keys | Sort-Object) {
    $server = $Servers[$name]
    $command = [System.Collections.Generic.List[string]]::new()
    $cmdProp = $server.PSObject.Properties['command']
    if ($cmdProp -and $cmdProp.Value) { [void]$command.Add($cmdProp.Value) }
    $argsProp = $server.PSObject.Properties['args']
    if ($argsProp -and $argsProp.Value) { foreach ($a in $argsProp.Value) { [void]$command.Add($a) } }
    $cfg = [ordered]@{
      type = 'local'
      command = $command.ToArray()
      enabled = $true
    }
    $cwdProp = $server.PSObject.Properties['cwd']
    if ($cwdProp -and $cwdProp.Value) { $cfg.cwd = $cwdProp.Value }
    $envProp = $server.PSObject.Properties['env']
    if ($envProp -and $envProp.Value) {
      $envMap = [ordered]@{}
      foreach ($prop in $envProp.Value.PSObject.Properties) { $envMap[$prop.Name] = $prop.Value }
      if ($envMap.Count -gt 0) { $cfg.environment = $envMap }
    }
    $ocServers[$name] = $cfg
  }
  return $ocServers
}

function Write-OpenCodeConfig {
  # OpenCode reads project config from <repo>\opencode.json (project root),
  # not from a ".opencode" subfolder. Merge into any existing file instead
  # of overwriting it, so hand-edited settings (model, agent, plugin, ...)
  # survive re-runs of this script.
  param([string]$RepoPath, [System.Collections.Specialized.OrderedDictionary]$McpServers, [switch]$DryRun)
  $path = Join-Path $RepoPath 'opencode.json'
  $obj = [ordered]@{}
  if (Test-Path $path) {
    try {
      $existing = Get-Content $path -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($prop in $existing.PSObject.Properties) { $obj[$prop.Name] = $prop.Value }
    } catch {
      Write-Warning "Existing opencode.json at $path is invalid JSON; it will be replaced."
    }
  }
  if (-not $obj.Contains('$schema')) { $obj['$schema'] = 'https://opencode.ai/config.json' }
  $obj['mcp'] = $McpServers
  $json = $obj | ConvertTo-Json -Depth 10
  if ($DryRun) { Write-Host "  [dry] write $path"; return }
  Set-Content -Path $path -Value $json -Encoding UTF8
  Write-Host "  wrote $path"
}

function Write-McpConfigs {
  param(
    [string]$RepoPath,
    [string[]]$Ides,
    [hashtable]$Vars,
    [string[]]$ServerNames,
    [string[]]$ManagedServers,
    [object]$SkipIdes,
    [switch]$DryRun
  )
  # New IDEs: add a switch arm below. Server payloads (including mongodb
  # launched via node + global entry, not npx) come from mcp/*.template.json.
  $allServers = Merge-McpJsonTemplates -HubPath $Vars['HUB'] -Vars $Vars -ServerNames $ServerNames
  if ([string]::IsNullOrWhiteSpace($Vars['CONTEXT7_API_KEY'])) {
    $ctx = $allServers['context7']
    if ($ctx) {
      $ctxArgs = @($ctx.args)
      $idx = [array]::IndexOf($ctxArgs, '--api-key')
      if ($idx -ge 0) {
        $newArgs = [System.Collections.Generic.List[string]]::new()
        $newArgs.AddRange([string[]]$ctxArgs)
        $newArgs.RemoveAt($idx)
        if ($idx -lt $newArgs.Count) { $newArgs.RemoveAt($idx) }
        $ctx.args = $newArgs.ToArray()
      }
    }
  }

  foreach ($ide in $Ides) {
    $ideServers = Select-McpServersForIde -Servers $allServers -Ide $ide -SkipIdes $SkipIdes
    # ConvertTo-Json on OrderedDictionary is an array of {Key,Value} in Windows
    # PowerShell 5.1. Flatten to a plain hashtable before serializing.
    $plain = @{}
    foreach ($k in $ideServers.Keys) { $plain[$k] = $ideServers[$k] }
    switch ($ide) {
      'Cursor' {
        $path = Join-Path $RepoPath '.cursor\mcp.json'
        Write-McpJsonMerged -Path $path -HubServers $plain -ServersProperty 'mcpServers' -ManagedServerNames $ManagedServers -DryRun:$DryRun
      }
      'VSCode' {
        $path = Join-Path $RepoPath '.vscode\mcp.json'
        Write-McpJsonMerged -Path $path -HubServers $plain -ServersProperty 'servers' -ManagedServerNames $ManagedServers -DryRun:$DryRun
      }
      'Kiro' {
        $path = Join-Path $RepoPath '.kiro\settings\mcp.json'
        Write-McpJsonMerged -Path $path -HubServers $plain -ServersProperty 'mcpServers' -ManagedServerNames $ManagedServers -DryRun:$DryRun
      }
      'Qoder' {
        $path = Join-Path $RepoPath '.qoder\mcp.json'
        Write-McpJsonMerged -Path $path -HubServers $plain -ServersProperty 'mcpServers' -ManagedServerNames $ManagedServers -DryRun:$DryRun
      }
      'OpenCode' {
        # Project config lives at <repo>\opencode.json (opencode.ai/docs/config),
        # and "mcp" is a flat map of servers (opencode.ai/docs/mcp-servers).
        $ocServers = ConvertTo-OpenCodeMcpServers -Servers $plain
        Write-OpenCodeConfig -RepoPath $RepoPath -McpServers $ocServers -DryRun:$DryRun
      }
      'Antigravity' {
        # Antigravity (IDE/CLI) reads workspace MCP config from .agents\mcp_config.json
        # (global fallback is ~/.gemini/config/mcp_config.json). It does NOT use
        # a project-level ".antigravity" folder for MCP.
        $path = Join-Path $RepoPath '.agents\mcp_config.json'
        Write-McpJsonMerged -Path $path -HubServers $plain -ServersProperty 'mcpServers' -ManagedServerNames $ManagedServers -DryRun:$DryRun
      }
      'Claude' {
        # Claude Code project MCP is <repo>\.mcp.json (code.claude.com/docs/en/mcp).
        $path = Join-Path $RepoPath '.mcp.json'
        Write-McpJsonMerged -Path $path -HubServers $plain -ServersProperty 'mcpServers' -ManagedServerNames $ManagedServers -DryRun:$DryRun
      }
      'Devin' {
        # Devin CLI (v3000.3+) reads .devin\mcp_config.json (docs.devin.ai
        # cli/extensibility/mcp/configuration). Older .devin\mcp.json is leftover.
        $path = Join-Path $RepoPath '.devin\mcp_config.json'
        Write-McpJsonMerged -Path $path -HubServers $plain -ServersProperty 'mcpServers' -ManagedServerNames $ManagedServers -DryRun:$DryRun
      }
    }
  }
}

function Write-TextFile {
  param([string]$Path, [string]$Content, [switch]$DryRun)
  $dir = Split-Path -Parent $Path
  if ($DryRun) {
    Write-Host "  [dry] write $Path"
    return
  }
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  Set-Content -Path $Path -Value $Content -Encoding UTF8
  Write-Host "  wrote $Path"
}

function Write-McpJsonMerged {
  # Merges hub-managed MCP servers into an existing JSON config file.
  # - Preserves ALL top-level properties (inputs, globalSettings, etc.)
  # - Preserves user-added servers not managed by the hub
  # - Removes stale hub servers no longer assigned to this project
  # $ManagedServerNames is the full hub catalog so we can prune leftovers.
  param(
    [string]$Path,
    [hashtable]$HubServers,
    [string]$ServersProperty,  # 'mcpServers' or 'servers'
    [string[]]$ManagedServerNames,
    [switch]$DryRun
  )
  $dir = Split-Path -Parent $Path
  if ($DryRun) { Write-Host "  [dry] write $Path"; return }
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }

  # Read existing file preserving all top-level keys
  $topLevel = [ordered]@{}
  $existingServers = [ordered]@{}
  if (Test-Path $Path) {
    try {
      $existing = Get-Content $Path -Raw -Encoding UTF8 | ConvertFrom-Json
      foreach ($prop in $existing.PSObject.Properties) {
        if ($prop.Name -eq $ServersProperty) {
          if ($prop.Value) {
            foreach ($sp in $prop.Value.PSObject.Properties) {
              $existingServers[$sp.Name] = $sp.Value
            }
          }
        } else {
          $topLevel[$prop.Name] = $prop.Value
        }
      }
    } catch {
      Write-Warning "Existing $Path is invalid JSON; hub servers will replace it."
    }
  }

  # Remove stale hub-managed servers (in the catalog but not in this project's set)
  if ($ManagedServerNames) {
    foreach ($name in $ManagedServerNames) {
      if ($existingServers.Contains($name) -and -not $HubServers.ContainsKey($name)) {
        $existingServers.Remove($name)
      }
    }
  }

  # Upsert current hub servers
  foreach ($k in $HubServers.Keys) { $existingServers[$k] = $HubServers[$k] }

  # Rebuild the full object with original top-level props preserved
  $output = [ordered]@{}
  foreach ($k in $topLevel.Keys) { $output[$k] = $topLevel[$k] }
  $output[$ServersProperty] = $existingServers
  $json = $output | ConvertTo-Json -Depth 10
  Set-Content -Path $Path -Value $json -Encoding UTF8
  Write-Host "  wrote $Path (merged)"
}

function Write-PointerRules {
  param(
    [string]$RepoPath,
    [string]$HubPath,
    [object]$FamilyCfg,
    [string[]]$Ides,
    [switch]$DryRun
  )
  if ($Ides -notcontains 'Cursor') { return }
  $rulesDir = Join-Path $RepoPath '.cursor\rules'
  if ($FamilyCfg.cursorRule) {
    $src = Join-Path $HubPath "templates\rules\$($FamilyCfg.cursorRule)"
    $dest = Join-Path $rulesDir $FamilyCfg.cursorRule
    if (Test-Path $src) {
      if ($DryRun) { Write-Host "  [dry] rule $($FamilyCfg.cursorRule)" }
      else {
        if (-not (Test-Path $rulesDir)) { New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null }
        Copy-Item $src $dest -Force
        Write-Host "  rule $($FamilyCfg.cursorRule)"
      }
    }
  }
  foreach ($extra in @($FamilyCfg.extraRules)) {
    if (-not $extra) { continue }
    $src = Join-Path $HubPath "templates\rules\$extra"
    $dest = Join-Path $rulesDir $extra
    if (Test-Path $src) {
      if ($DryRun) { Write-Host "  [dry] rule $extra" }
      else {
        if (-not (Test-Path $rulesDir)) { New-Item -ItemType Directory -Force -Path $rulesDir | Out-Null }
        Copy-Item $src $dest -Force
        Write-Host "  rule $extra"
      }
    }
  }
}

function Write-SlimStubs {
  param([string]$RepoPath, [string[]]$Ides, [switch]$DryRun)
  $stub = @"
<!-- Point to AGENTS.md - full stack guides live in D:\AGENTS skills (on demand). -->
See **AGENTS.md**. Load stack skills from the linked `D:\AGENTS` instead of duplicating guides here.
"@
  $targets = @()
  if ($Ides -contains 'Cursor') {
    $targets += (Join-Path $RepoPath '.cursorrules')
  }
  if (Test-Path (Join-Path $RepoPath 'GEMINI.md')) {
    # Gemini CLI / Antigravity load GEMINI.md hierarchically from the
    # workspace root (geminicli.com/docs/cli/gemini-md); only slim it if the
    # repo already has one. We do NOT create .gemini\GEMINI.md per project -
    # ~/.gemini is a global, per-user file, not a per-project folder.
    $targets += (Join-Path $RepoPath 'GEMINI.md')
  }
  foreach ($t in $targets) {
    if ($DryRun) { Write-Host "  [dry] stub $(Split-Path $t -Leaf)"; continue }
    $dir = Split-Path -Parent $t
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
    Set-Content -Path $t -Value $stub -Encoding UTF8
    Write-Host "  stub $(Split-Path $t -Leaf)"
  }
}

function Write-CopilotPointer {
  param(
    [string]$RepoPath,
    [string]$HubPath,
    [string]$Family,
    [switch]$DryRun
  )
  $src = Join-Path $HubPath "templates\copilot\$Family.md"
  if (-not (Test-Path $src)) { return }
  $dest = Join-Path $RepoPath '.github\copilot-instructions.md'
  $content = Get-Content $src -Raw -Encoding UTF8
  if ($DryRun) { Write-Host "  [dry] copilot-instructions.md"; return }
  $dir = Split-Path -Parent $dest
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  Set-Content -Path $dest -Value $content -Encoding UTF8
  Write-Host "  wrote .github/copilot-instructions.md"
}

function Write-AntigravityPointer {
  # Antigravity (IDE/CLI) discovers workspace rules under .agents\rules\*.md
  # (see "Where does Antigravity look for Rules and Workflows?", prototypr.io).
  # There is no project-level ".antigravity" folder for rules/skills.
  param(
    [string]$RepoPath,
    [string]$HubPath,
    [string[]]$Ides,
    [switch]$DryRun
  )
  $agDir = Join-Path $RepoPath '.agents\rules'
  if ($Ides -notcontains 'Antigravity') { return }
  $src = Join-Path $HubPath 'templates\antigravity\rules.md'
  if (-not (Test-Path $src)) { return }
  $dest = Join-Path $agDir 'stack-pointer.md'
  $content = Get-Content $src -Raw -Encoding UTF8
  if ($DryRun) { Write-Host "  [dry] .agents/rules/stack-pointer.md"; return }
  if (-not (Test-Path $agDir)) { New-Item -ItemType Directory -Force -Path $agDir | Out-Null }
  Set-Content -Path $dest -Value $content -Encoding UTF8
  Write-Host "  wrote .agents/rules/stack-pointer.md"
}

function Write-KiroSteeringPointer {
  # Kiro steering files live in .kiro\steering\*.md and are always-on by
  # default (kiro.dev/docs/steering). Write a slim pointer so Kiro's native
  # mechanism also carries the "load skills on demand" convention, instead
  # of relying only on AGENTS.md.
  param(
    [string]$RepoPath,
    [string]$ProjectName,
    [string[]]$Ides,
    [switch]$DryRun
  )
  if ($Ides -notcontains 'Kiro') { return }
  $dir = Join-Path $RepoPath '.kiro\steering'
  $dest = Join-Path $dir 'stack-pointer.md'
  $content = @"
---
inclusion: always
---

# $ProjectName

See **AGENTS.md** for stack, commands, and skills. Full stack guides live in
``D:\AGENTS`` skills (junctions under ``.kiro/skills``); load them on demand
instead of duplicating guides here.
"@
  if ($DryRun) { Write-Host "  [dry] .kiro/steering/stack-pointer.md"; return }
  if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Force -Path $dir | Out-Null }
  Set-Content -Path $dest -Value $content -Encoding UTF8
  Write-Host "  wrote .kiro/steering/stack-pointer.md"
}

function Remove-FatAlwaysOnRules {
  param([string]$RepoPath, [switch]$DryRun)
  $fatRules = @(
    (Join-Path $RepoPath '.cursor\rules\nestjs-rules.mdc'),
    (Join-Path $RepoPath '.cursor\rules\cursor.mdc'),
    (Join-Path $RepoPath '.cursor\rules\.cursorrules.mdc')
  )
  # Only remove files that were originally generated by the hub or contain
  # known hub/legacy content markers. This avoids deleting project-specific
  # rules that happen to share the same filename.
  $hubMarkers = @('AgentHub', 'Install-AgentHub', 'alwaysApply:', 'nestjs-clean-architecture', 'D:\AGENTS')
  foreach ($fr in $fatRules) {
    if (-not (Test-Path $fr)) { continue }
    $content = Get-Content $fr -Raw -Encoding UTF8 -ErrorAction SilentlyContinue
    $isHubGenerated = $false
    foreach ($marker in $hubMarkers) {
      if ($content -and $content.Contains($marker)) { $isHubGenerated = $true; break }
    }
    if (-not $isHubGenerated) {
      Write-Warning "Skipping removal of $(Split-Path $fr -Leaf) — does not appear hub-generated. Remove manually if unneeded."
      continue
    }
    if ($DryRun) { Write-Host "  [dry] remove fat rule $(Split-Path $fr -Leaf)"; continue }
    Remove-Item $fr -Force
    Write-Host "  removed fat rule $(Split-Path $fr -Leaf)"
  }
}

function Remove-LegacyAgentPaths {
  # Cleans up artifacts written by older versions of this script or by
  # non-integrated IDEs (Gemini CLI, Windsurf). Opt-in via -MigrateLegacyPaths
  # because it deletes files (reversible: this script regenerates the
  # integrated-IDE equivalents). Adds .gemini/skills, .gemini/hooks,
  # .windsurfrules and CLAUDE.md because the hub now uses .agents/skills,
  # AGENTS.md, MCP and Cursor/PowerShell hooks managed by Fix-CursorHooks.ps1.
  param([string]$RepoPath, [switch]$DryRun)
  $legacy = @(
    (Join-Path $RepoPath '.antigravity\mcp.json'),
    (Join-Path $RepoPath '.antigravity\.antigravityrules'),
    (Join-Path $RepoPath '.antigravity\skills'),
    (Join-Path $RepoPath '.opencode\opencode.json'),
    (Join-Path $RepoPath '.devin\mcp.json'),
    (Join-Path $RepoPath '.gemini\GEMINI.md'),
    (Join-Path $RepoPath '.gemini\skills'),
    (Join-Path $RepoPath '.gemini\hooks'),
    (Join-Path $RepoPath '.windsurfrules'),
    (Join-Path $RepoPath 'CLAUDE.md')
  )
  foreach ($p in $legacy) {
    if (-not (Test-Path $p)) { continue }
    if ($DryRun) { Write-Host "  [dry] remove legacy $p"; continue }
    Remove-Item $p -Recurse -Force
    Write-Host "  removed legacy $p"
  }
  # Remove now-empty legacy parent folders (.antigravity, .gemini) but leave
  # anything the user may have added by hand.
  foreach ($parent in @((Join-Path $RepoPath '.antigravity'), (Join-Path $RepoPath '.gemini'))) {
    if ((Test-Path $parent) -and -not $DryRun) {
      $remaining = Get-ChildItem $parent -Force -ErrorAction SilentlyContinue
      if (-not $remaining) { Remove-Item $parent -Force }
    }
  }
}

function Remove-UnusedIdeFolders {
  param([string]$RepoPath, [string[]]$Folders, [switch]$DryRun)
  foreach ($name in $Folders) {
    $path = Join-Path $RepoPath $name
    if (-not (Test-Path $path)) { continue }
    if ($DryRun) { Write-Host "  [dry] remove $name"; continue }
    Remove-Item $path -Recurse -Force
    Write-Host "  removed $name"
  }
}

function Get-IdeFolders {
  # Maps an IDE name to the project-relative folder paths it owns.
  # Used by Remove-ExcludedIdeFolders to clean up IDE folders for excluded IDEs.
  param([string]$Ide)
  switch ($Ide) {
    'Cursor'      { return @('.cursor') }
    'VSCode'      { return @('.vscode') }
    'Kiro'        { return @('.kiro') }
    'OpenCode'    { return @('.opencode') }
    'Antigravity' { return @('.agents') }
    'Claude'      { return @('.claude') }
    'Codex'       { return @('.codex') }
    'Devin'       { return @('.devin') }
    'Qoder'       { return @('.qoder') }
    default       { return @() }
  }
}

function Remove-ExcludedIdeFolders {
  # Removes project folders belonging to IDEs listed in excludeIdes.
  # Only removes folders that contain hub-managed content (skills junctions,
  # MCP configs, etc.). Safe to re-run: if the IDE is moved back to the active
  # list, Install will recreate the folders.
  param([string]$RepoPath, [string[]]$ExcludeIdes, [switch]$DryRun)
  if (-not $ExcludeIdes -or $ExcludeIdes.Count -eq 0) { return }
  foreach ($ide in $ExcludeIdes) {
    $folders = Get-IdeFolders -Ide $ide
    foreach ($rel in $folders) {
      $path = Join-Path $RepoPath $rel
      if (-not (Test-Path $path)) { continue }
      if ($DryRun) { Write-Host "  [dry] remove excluded IDE folder $rel ($ide)"; continue }
      Remove-Item $path -Recurse -Force
      Write-Host "  removed excluded IDE folder $rel ($ide)"
    }
  }
  # Also remove top-level files that belong to excluded IDEs
  $topLevelFiles = @()
  if ($ExcludeIdes -contains 'Claude') { $topLevelFiles += '.mcp.json' }
  if ($ExcludeIdes -contains 'Cursor') { $topLevelFiles += '.cursorrules' }
  foreach ($f in $topLevelFiles) {
    $path = Join-Path $RepoPath $f
    if (-not (Test-Path $path)) { continue }
    if ($DryRun) { Write-Host "  [dry] remove excluded IDE file $f"; continue }
    Remove-Item $path -Force
    Write-Host "  removed excluded IDE file $f"
  }
}

function Link-ProjectSkills {
  param(
    [string]$RepoPath,
    [string]$HubPath,
    [string[]]$SkillNames,
    [string[]]$Ides,
    [switch]$DryRun
  )
  $skillRoots = [System.Collections.Generic.List[string]]::new()
  if ($Ides -contains 'Cursor') { [void]$skillRoots.Add((Join-Path $RepoPath '.cursor\skills')) }
  if ($Ides -contains 'VSCode') {
    # GitHub Copilot (VS Code / Copilot CLI) discovers project skills at
    # .github\skills\<name>\SKILL.md
    [void]$skillRoots.Add((Join-Path $RepoPath '.github\skills'))
  }
  if ($Ides -contains 'Antigravity') {
    # Antigravity workspace skills live under .agents\skills (see
    # codelabs.developers.google.com/autonomous-ai-developer-pipelines-antigravity).
    [void]$skillRoots.Add((Join-Path $RepoPath '.agents\skills'))
  }
  if ($Ides -contains 'Kiro') {
    # Kiro also discovers project-level skills at .kiro\skills\<name>\SKILL.md
    [void]$skillRoots.Add((Join-Path $RepoPath '.kiro\skills'))
  }
  if ($Ides -contains 'OpenCode') {
    # OpenCode discovers skills at .opencode\skills (docs.opencode.ai/docs/skills).
    [void]$skillRoots.Add((Join-Path $RepoPath '.opencode\skills'))
  }
  if ($Ides -contains 'Claude') {
    # Claude Code discovers project skills at .claude\skills\<name>\SKILL.md
    [void]$skillRoots.Add((Join-Path $RepoPath '.claude\skills'))
  }
  if ($Ides -contains 'Codex') {
    # Codex discovers project skills at .codex\skills\<name>\SKILL.md
    [void]$skillRoots.Add((Join-Path $RepoPath '.codex\skills'))
  }
  if ($Ides -contains 'Devin') {
    # Devin discovers SKILL.md under .devin\skills (docs.devin.ai/product-guides/skills).
    [void]$skillRoots.Add((Join-Path $RepoPath '.devin\skills'))
  }

  foreach ($root in $skillRoots) {
    foreach ($skill in $SkillNames) {
      $target = Join-Path $HubPath "skills\$skill"
      $link = Join-Path $root $skill
      New-JunctionOrCopy -LinkPath $link -TargetPath $target -DryRun:$DryRun
    }
  }
}

# --- main ---
$HubPath = Resolve-HubPath -Path $HubPath

$catalogPath = Join-Path $HubPath 'catalog\projects.json'
$catalog = Get-Content $catalogPath -Raw -Encoding UTF8 | ConvertFrom-Json

$defaultSistemas = 'D:\SISTEMAS'
# Project repositories are direct children of these family folders. Keep this
# list deliberately narrow: other D:\SISTEMAS folders are not managed by
# default.
$defaultProjectRoots = @('ERPCLASS', 'MOBICLASS', 'NFECLASS', 'SHOPCLASS')

if ($Roots.Count -eq 0) {
  $Roots = @($defaultProjectRoots |
    ForEach-Object { Join-Path $defaultSistemas $_ } |
    Where-Object { Test-Path $_ })
} else {
  # Accept D:\SISTEMAS as a convenient container root too. The main loop
  # intentionally scans only one level, so expand it to the managed family
  # folders before enumerating project repositories.
  $Roots = @($Roots | ForEach-Object {
    $root = $_
    $managedChildren = @($defaultProjectRoots |
      ForEach-Object { Join-Path $root $_ } |
      Where-Object { Test-Path $_ })
    if ($managedChildren.Count -gt 0) { $managedChildren } else { $root }
  })
}
$families = @{}
foreach ($prop in $catalog.families.PSObject.Properties) {
  $families[$prop.Name] = $prop.Value
}

$commonSkills = @()
if ($catalog.PSObject.Properties.Name -contains 'commonSkills') {
  $commonSkills = @($catalog.commonSkills)
}

# Guard: verify every native hub skill (skills/<name>/SKILL.md, not the
# vendor-mirrored ones) has real content before linking anything into
# projects. Junctions faithfully propagate an empty source directory to all
# 24+ repos with no error, so a corrupted/emptied skill here would silently
# strip that skill's instructions everywhere it's used.
$hubSkillsRoot = Join-Path $HubPath 'skills'
$allSkillNamesInUse = [System.Collections.Generic.HashSet[string]]::new()
foreach ($s in $commonSkills) { [void]$allSkillNamesInUse.Add($s) }
foreach ($prop in $catalog.families.PSObject.Properties) {
  foreach ($s in @($prop.Value.skills)) { [void]$allSkillNamesInUse.Add($s) }
}
$emptySkills = @()
foreach ($name in $allSkillNamesInUse) {
  $skillDir = Join-Path $hubSkillsRoot $name
  if (-not (Test-Path $skillDir)) { continue } # vendor-mirrored skills not yet linked; Ensure-VendorSkillMirrors handles those
  $item = Get-Item $skillDir -Force
  $isReparse = [bool]($item.Attributes -band [IO.FileAttributes]::ReparsePoint)
  if ($isReparse) { continue } # vendor mirror; validated by Test-SkillTargetHasContent when re-linked below
  if (-not (Test-SkillTargetHasContent -TargetPath $skillDir)) { $emptySkills += $name }
}
if ($emptySkills.Count -gt 0) {
  throw "Native hub skill folder(s) are empty (0 bytes of content): $($emptySkills -join ', '). Refusing to link empty skills into every project. Restore content first, e.g.: git -C `"$HubPath`" checkout -- $(($emptySkills | ForEach-Object { "skills/$_" }) -join ' ')"
}

Ensure-VendorSkillMirrors -HubPath $HubPath -SkillNames $commonSkills -DryRun:$DryRun
if ($allSkillNamesInUse.Contains('claude-android-ninja')) {
  Ensure-VendorStandaloneSkill `
    -HubPath $HubPath `
    -SkillName 'claude-android-ninja' `
    -VendorRelativePath 'vendor/claude-android-ninja' `
    -Url 'https://github.com/Drjacky/claude-android-ninja.git' `
    -DryRun:$DryRun
}
$allowedIdes = @($catalog.ides)
$qoderOptIn = [bool]$catalog.qoderOptIn
$detected = Get-DetectedIdes -Override $Ides -Allowed $allowedIdes -IncludeQoder:($IncludeQoder -or $qoderOptIn)
if ($detected.Count -eq 0) { Write-Warning 'No allowed IDEs detected. Use -Ides to force or update catalog ides list.' }

$context7ApiKey = $env:CONTEXT7_API_KEY
if ([string]::IsNullOrWhiteSpace($context7ApiKey)) {
  Write-Warning 'CONTEXT7_API_KEY not set; context7 MCP will run with public rate limits (get a key at context7.com/dashboard).'
  $context7ApiKey = ''
}
$mongoLaunch = Resolve-MongodbMcpLaunch -DryRun:$DryRun
if ($mongoLaunch -is [System.Array]) {
  $mongoLaunch = $mongoLaunch |
    Where-Object { $_ -and $_.PSObject.Properties['Node'] } |
    Select-Object -Last 1
}
if (-not ($mongoLaunch -and $mongoLaunch.PSObject.Properties['Node'])) {
  $mongoLaunch = $null
}
Warn-GlobalCursorMongodbDuplicate
$mcpBaseVars = @{
  HUB = $HubPath
  CONTEXT7_API_KEY = $context7ApiKey
  MDB_MCP_CONNECTION_STRING = if ($env:MDB_MCP_CONNECTION_STRING) { $env:MDB_MCP_CONNECTION_STRING } else { 'mongodb://root:password@127.0.0.1:27017/erpclass?authSource=admin' }
}
if ($mongoLaunch) {
  $mcpBaseVars['NODE'] = $mongoLaunch.Node
  $mcpBaseVars['MDB_MCP_ENTRY'] = $mongoLaunch.Entry
}
$managedMcpServers = Get-ManagedMcpServerNames -Catalog $catalog -Families $families
$mcpSkipIdes = $null
if ($catalog.mcp) { $mcpSkipIdes = $catalog.mcp.skipIdes }

Write-Host "Hub: $HubPath"
Write-Host "IDEs: $($detected -join ', ')"
Write-Host "Roots: $($Roots -join ', ')"
if ($DryRun) { Write-Host 'DRY RUN - no changes' }

$exclude = @($catalog.excludeProjectNames)
$stats = @{ projects = 0; linked = 0 }

foreach ($root in $Roots) {
  Get-ChildItem $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
    $proj = $_
    if ($exclude -contains $proj.Name) { return }
    $family = Get-ProjectFamily -Name $proj.Name -Families $families
    # skip non-repos without AGENTS and without src/source (Android Gradle
    # trees and the android family are included even when the git root is
    # only a wrapper around src/ or Android Studio metadata).
    $looksLikeProject = (Test-Path (Join-Path $proj.FullName 'AGENTS.md')) -or
      (Test-Path (Join-Path $proj.FullName 'src')) -or
      (Test-Path (Join-Path $proj.FullName 'source')) -or
      (Test-Path (Join-Path $proj.FullName 'package.json')) -or
      (Test-Path (Join-Path $proj.FullName '.git')) -or
      (Test-Path (Join-Path $proj.FullName 'settings.gradle')) -or
      (Test-Path (Join-Path $proj.FullName 'settings.gradle.kts')) -or
      (Test-Path (Join-Path $proj.FullName 'build.gradle')) -or
      (Test-Path (Join-Path $proj.FullName 'app')) -or
      ($family -eq 'android')
    if (-not $looksLikeProject) { return }

    $cfg = $families[$family]
    Write-Host "`n=== $($proj.Name) [$family] ==="
    $stats.projects++

    $skillNames = @($commonSkills) + @($cfg.skills)
    Link-ProjectSkills -RepoPath $proj.FullName -HubPath $HubPath -SkillNames $skillNames -Ides $detected -DryRun:$DryRun
    $hubRefs = Join-Path $HubPath 'references'
    if (Test-Path $hubRefs) {
      New-JunctionOrCopy -LinkPath (Join-Path $proj.FullName 'references') -TargetPath $hubRefs -DryRun:$DryRun
    }
    $mcpVars = $mcpBaseVars.Clone()
    $mcpVars['REPO'] = $proj.FullName
    $mcpServers = Get-ProjectMcpServerNames -ProjectName $proj.Name -FamilyCfg $cfg -Catalog $catalog
    if (-not $mongoLaunch) {
      $mcpServers = @($mcpServers | Where-Object { $_ -ne 'mongodb' })
    }
    if ($mcpServers -contains 'openapi') {
      $oa = Get-NestSwaggerMcpVars -RepoPath $proj.FullName
      if ($oa) {
        $mcpVars['API_BASE_URL'] = $oa.API_BASE_URL
        $mcpVars['OPENAPI_SPEC_PATH'] = $oa.OPENAPI_SPEC_PATH
        Write-Host "  OpenAPI spec: $($oa.OPENAPI_SPEC_PATH)"
      } else {
        $mcpServers = @($mcpServers | Where-Object { $_ -ne 'openapi' })
      }
    }
    Write-Host "  MCP: $($mcpServers -join ', ')"
    Write-McpConfigs -RepoPath $proj.FullName -Ides $detected -Vars $mcpVars -ServerNames $mcpServers -ManagedServers $managedMcpServers -SkipIdes $mcpSkipIdes -DryRun:$DryRun
    Write-PointerRules -RepoPath $proj.FullName -HubPath $HubPath -FamilyCfg $cfg -Ides $detected -DryRun:$DryRun
    Write-CopilotPointer -RepoPath $proj.FullName -HubPath $HubPath -Family $family -DryRun:$DryRun
    Write-AntigravityPointer -RepoPath $proj.FullName -HubPath $HubPath -Ides $detected -DryRun:$DryRun
    Write-KiroSteeringPointer -RepoPath $proj.FullName -ProjectName $proj.Name -Ides $detected -DryRun:$DryRun
    Remove-FatAlwaysOnRules -RepoPath $proj.FullName -DryRun:$DryRun

    if (-not $SkipCodegraphInit) {
      Ensure-CodegraphInit -RepoPath $proj.FullName -Skills @($cfg.skills) -DryRun:$DryRun
    }

    $agentsPath = Join-Path $proj.FullName 'AGENTS.md'
    $writeAgentsHere = $WriteAgents -or $ForceAgents -or (
      ($family -eq 'android') -and -not (Test-Path $agentsPath)
    )
    if ($writeAgentsHere) {
      $tpl = Join-Path $HubPath "templates\agents\$($cfg.agentsTemplate)"
      Write-AgentsFile -RepoPath $proj.FullName -ProjectName $proj.Name -TemplatePath $tpl -Force:$ForceAgents -DryRun:$DryRun
      Write-SlimStubs -RepoPath $proj.FullName -Ides $detected -DryRun:$DryRun
    }

    if ($RemoveUnusedIdeFolders) {
      $toRemove = @($catalog.unusedIdeFolders)
      Remove-UnusedIdeFolders -RepoPath $proj.FullName -Folders $toRemove -DryRun:$DryRun
    }
    # Always remove folders for excluded IDEs (keeps projects clean)
    $excludeIdes = @()
    if ($catalog.excludeIdes) { $excludeIdes = @($catalog.excludeIdes) }
    Remove-ExcludedIdeFolders -RepoPath $proj.FullName -ExcludeIdes $excludeIdes -DryRun:$DryRun
    if ($MigrateLegacyPaths) {
      Remove-LegacyAgentPaths -RepoPath $proj.FullName -DryRun:$DryRun
    }
    $stats.linked++
  }
}

Write-Host "`nDone. Projects: $($stats.projects)"
Write-Host "Tip: commit slim AGENTS.md per repo; junctions are local (re-run this script on each machine)."
