<#
.SYNOPSIS
  Links D:\AGENTS skills into ERPCLASS / NFECLASS / MOBICLASS / SHOPCLASS repos (D:\SISTEMAS).

.DESCRIPTION
  - Detects installed IDEs (Cursor, VS Code, Kiro, OpenCode, Antigravity, Claude Code, Codex, Devin)
  - Creates junctions from hub skills into each project
  - Writes slim AGENTS.md (preserves ## Local section)
  - Generates MCP configs only for detected IDEs
  - Optionally removes unused IDE folders (.qoder, .codebuddy)
  - Runs "code-review-graph build --repo <path>" for projects using that
    skill that don't have a ".code-review-graph" folder yet (skip with
    -SkipCodeReviewGraph, force a rebuild with -ForceCodeReviewGraphBuild).
    Uses a dedicated venv (.venv-code-review-graph, created on first run)
    instead of the system Python: the Microsoft Store Python's user-site
    packages are invisible to code-review-graph's "python -I" tree-sitter
    probe, which silently produces EMPTY graphs (0 nodes) for every
    non-Python language. The venv is also used for the MCP "serve" command.
    Does NOT run "code-review-graph install": that CLI subcommand overwrites
    the merged mcp.json files this script writes and duplicates AGENTS.md
    content already managed here.

.EXAMPLE
  .\Install-AgentHub.ps1 -RemoveUnusedIdeFolders -WriteAgents

.EXAMPLE
  .\Install-AgentHub.ps1 -Ides Cursor,VSCode,Kiro -DryRun

.EXAMPLE
  # One-time cleanup of paths written by older script versions
  # (.antigravity\mcp.json, .opencode\opencode.json, .gemini\GEMINI.md, .codex\claude)
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
  [switch]$SkipCodeReviewGraph,
  [switch]$ForceCodeReviewGraphBuild
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Resolve-HubPath {
  param([string]$Path)
  if ($Path) { return (Resolve-Path $Path).Path }
  $scriptDir = Split-Path -Parent $PSScriptRoot
  if (Test-Path (Join-Path $scriptDir 'skills')) { return $scriptDir }
  $default = 'D:\IA\agents'
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
  if ((Test-Path (Join-Path $userHome '.antigravity')) -or (Test-Path (Join-Path $env:APPDATA 'Antigravity'))) {
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

function Test-UsablePythonExe {
  # Rejects missing files, 0-byte Windows Store aliases, and venv launchers
  # whose home Python was uninstalled (exit 103: "did not find executable").
  param([string]$Path, [string]$ImportModule = '')
  if (-not $Path -or -not (Test-Path $Path)) { return $false }
  $item = Get-Item $Path -Force -ErrorAction SilentlyContinue
  if (-not $item -or $item.Length -eq 0) { return $false }
  if ($Path -match '\\WindowsApps\\(python|py)\.exe$') { return $false }
  $code = if ($ImportModule) { "import $ImportModule" } else { 'import sys' }
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'SilentlyContinue'
  try {
    & $Path -c $code 2>$null | Out-Null
    return ($LASTEXITCODE -eq 0)
  } catch {
    return $false
  } finally {
    $ErrorActionPreference = $prev
  }
}

function Find-PythonExe {
  $localCore = @(Get-ChildItem (Join-Path $env:LOCALAPPDATA 'Python') -Directory -Filter 'pythoncore-*' -ErrorAction SilentlyContinue |
    ForEach-Object { Join-Path $_.FullName 'python.exe' })
  $candidates = @(
    (Join-Path $env:LOCALAPPDATA 'Python\pythoncore-3.14-64\python.exe'),
    (Join-Path $env:LOCALAPPDATA 'Python\bin\python.exe')
  ) + $localCore + @(
    "$env:LOCALAPPDATA\Programs\Python\Python314\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python313\python.exe",
    "$env:LOCALAPPDATA\Programs\Python\Python312\python.exe",
    (Get-Command py -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source),
    (Get-Command python -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source)
  ) | Where-Object { $_ } | Select-Object -Unique
  foreach ($c in $candidates) {
    if (Test-UsablePythonExe -Path $c) { return $c }
  }
  Write-Warning 'Python not found; MCP configs will use "python" on PATH.'
  return 'python'
}

function Get-CodeReviewGraphPython {
  # The system/Microsoft Store Python installs packages into the per-user
  # site-packages dir, which code-review-graph's tree-sitter availability
  # probe cannot see (it launches "python -I", which disables user-site).
  # That silently produces EMPTY graphs for every non-Python language
  # (javascript/typescript included) even though "build" exits 0. Using a
  # dedicated venv avoids this: venv site-packages are visible even under -I.
  # On a new machine the venv folder may exist but the launcher still points
  # at an uninstalled Store Python — treat that as missing and recreate.
  param([string]$HubPath, [string]$SystemPython, [switch]$DryRun)
  $venvDir = Join-Path $HubPath '.venv-code-review-graph'
  $venvPython = Join-Path $venvDir 'Scripts\python.exe'
  if (Test-UsablePythonExe -Path $venvPython -ImportModule 'code_review_graph') {
    return $venvPython
  }
  if ($DryRun) {
    Write-Host "  [dry] create venv $venvDir + pip install code-review-graph"
    return $venvPython
  }
  if (Test-Path $venvDir) {
    Write-Host "Existing venv at $venvDir is broken (Python home missing); recreating."
    Remove-Item $venvDir -Recurse -Force
  }
  Write-Host "Creating dedicated venv for code-review-graph: $venvDir"
  & $SystemPython -m venv $venvDir
  if ($LASTEXITCODE -ne 0 -or -not (Test-Path $venvPython)) {
    Write-Warning "Failed to create venv at $venvDir; falling back to $SystemPython (tree-sitter parsers may be unavailable for non-Python languages)."
    return $SystemPython
  }
  & $venvPython -m pip install --quiet --upgrade pip
  & $venvPython -m pip install --quiet code-review-graph
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "pip install code-review-graph failed in $venvDir; falling back to $SystemPython."
    return $SystemPython
  }
  return $venvPython
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
  return $vendor
}

function Ensure-VendorSkillMirrors {
  # Junctions from hub skills/ + references/ into the vendor clone.
  # These paths are gitignored; this function is what makes a fresh clone usable.
  param([string]$HubPath, [string[]]$SkillNames, [switch]$DryRun)
  if (-not $SkillNames -or $SkillNames.Count -eq 0) { return }
  $vendor = Ensure-VendorAgentSkills -HubPath $HubPath -DryRun:$DryRun
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

function Get-ProjectFamily {
  param([string]$Name, [hashtable]$Families)
  $order = @('nestjs', 'angular', 'delphi')
  foreach ($key in $order) {
    foreach ($pattern in $Families[$key].match) {
      if ($Name -like $pattern) { return $key }
    }
  }
  return 'minimal'
}

function New-JunctionOrCopy {
  param([string]$LinkPath, [string]$TargetPath, [switch]$DryRun)
  if (-not (Test-Path $TargetPath)) {
    Write-Warning "Missing skill target: $TargetPath"
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
      if (-not $DryRun) { cmd /c "rmdir `"$LinkPath`"" | Out-Null }
    } else {
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
    $ok = $false
  }
  if ($ok) { Write-Host "  linked $LinkPath" }
}

function Ensure-CodeReviewGraphBuilt {
  # Runs "code-review-graph build --repo <path>" for projects that use the
  # code-review-graph skill and don't have a graph yet. Deliberately does NOT
  # call "code-review-graph install" here: that CLI command overwrites
  # .cursor\mcp.json / .vscode\mcp.json / .kiro\settings\mcp.json /
  # .qoder\mcp.json with a single-server config, wiping out the merged
  # context7 + filesystem servers that Write-McpConfigs already wrote, and it
  # duplicates AGENTS.md / .cursorrules content this hub already manages.
  param(
    [string]$RepoPath,
    [string[]]$Skills,
    [string]$PythonExe,
    [switch]$Force,
    [switch]$DryRun
  )
  if ($Skills -notcontains 'code-review-graph') { return }
  $graphDir = Join-Path $RepoPath '.code-review-graph'
  if ((Test-Path $graphDir) -and -not $Force) {
    return
  }
  if ($DryRun) {
    Write-Host "  [dry] $PythonExe -m code_review_graph build --repo $RepoPath"
    return
  }
  if (-not (Test-Path $PythonExe) -and -not (Get-Command $PythonExe -ErrorAction SilentlyContinue)) {
    Write-Warning "  code-review-graph python ($PythonExe) not found; skipping graph build for $RepoPath"
    return
  }
  Write-Host "  building code-review-graph for $RepoPath ..."
  & $PythonExe -m code_review_graph build --repo $RepoPath -q
  if ($LASTEXITCODE -ne 0) {
    Write-Warning "  code-review-graph build failed for $RepoPath (exit $LASTEXITCODE)"
    return
  }
  $gitignore = Join-Path $RepoPath '.gitignore'
  $entry = '.code-review-graph/'
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

function Merge-McpJsonTemplates {
  param([string]$HubPath, [hashtable]$Vars)
  $merged = @{}
  Get-ChildItem (Join-Path $HubPath 'mcp') -Filter '*.template.json' | Sort-Object Name | ForEach-Object {
    $file = $_
    $raw = Get-Content $file.FullName -Raw -Encoding UTF8
    $expanded = Expand-McpTemplate -Content $raw -Vars $Vars -JsonEscape
    try {
      $obj = $expanded | ConvertFrom-Json
    } catch {
      throw "Failed to parse MCP template $($file.Name): $_`n$expanded"
    }
    foreach ($prop in $obj.mcpServers.PSObject.Properties) {
      $merged[$prop.Name] = $prop.Value
    }
  }
  return @{ mcpServers = $merged }
}

function ConvertTo-TomlMcp {
  param([hashtable]$Servers, [string[]]$SkipProperties = @())
  $lines = [System.Collections.Generic.List[string]]::new()
  foreach ($name in $Servers.Keys | Sort-Object) {
    [void]$lines.Add("[mcp_servers.$name]")
    $server = $Servers[$name]
    foreach ($prop in $server.PSObject.Properties | Sort-Object Name) {
      if ($SkipProperties -contains $prop.Name) { continue }
      $val = $prop.Value
      if ($val -is [array] -or ($val -is [System.Collections.IEnumerable] -and $val -isnot [string])) {
        $parts = @($val | ForEach-Object { "`"$(ConvertTo-TomlBasicString $_)`"" })
        [void]$lines.Add("$($prop.Name) = [$($parts -join ', ')]")
      } else {
        [void]$lines.Add("$($prop.Name) = `"$(ConvertTo-TomlBasicString $val)`"")
      }
    }
    [void]$lines.Add('')
  }
  return ($lines -join "`r`n").TrimEnd()
}

function ConvertTo-OpenCodeMcpServers {
  # OpenCode's schema (https://opencode.ai/docs/mcp-servers) puts servers
  # directly under the top-level "mcp" key (no nested "servers" wrapper).
  param([hashtable]$Servers)
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
    if ($envProp -and $envProp.Value -and $envProp.Value.PSObject.Properties.Count -gt 0) {
      $envMap = [ordered]@{}
      foreach ($prop in $envProp.Value.PSObject.Properties) { $envMap[$prop.Name] = $prop.Value }
      $cfg.environment = $envMap
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

function Remove-TomlTablesByPrefix {
  # Drops TOML tables whose header is exactly one of $Prefixes or a nested
  # table under them (e.g. mcp_servers.context7.env).
  param([string]$Content, [string[]]$Prefixes)
  if ([string]::IsNullOrWhiteSpace($Content)) { return '' }
  $lines = $Content -split "`r?`n"
  $out = [System.Collections.Generic.List[string]]::new()
  $skip = $false
  foreach ($line in $lines) {
    if ($line -match '^\[([^\]]+)\]') {
      $table = $Matches[1]
      $skip = $false
      foreach ($p in $Prefixes) {
        if ($table -eq $p -or $table.StartsWith("$p.")) { $skip = $true; break }
      }
    }
    if ($skip) { continue }
    if ($line -match '^\s*# AgentHub-managed') { continue }
    [void]$out.Add($line)
  }
  return (($out -join "`r`n").TrimEnd())
}

function Write-CodexProjectConfig {
  # Codex reads project MCP from <repo>\.codex\config.toml (trusted projects
  # only; developers.openai.com/codex/mcp). Merge AgentHub servers into any
  # existing file so hand-edited keys survive. Do NOT write ~/.codex/config.toml:
  # a global code-review-graph cwd cannot be correct for every repo.
  param([string]$RepoPath, [string]$Toml, [switch]$DryRun)
  $path = Join-Path $RepoPath '.codex\config.toml'
  $prefixes = @('mcp_servers.code-review-graph', 'mcp_servers.context7', 'mcp_servers.filesystem')
  $existing = ''
  if (Test-Path $path) {
    $existing = Remove-TomlTablesByPrefix -Content (Get-Content $path -Raw -Encoding UTF8) -Prefixes $prefixes
  }
  $block = "# AgentHub-managed MCP servers (rewritten by Install-AgentHub.ps1).`r`n$Toml"
  $content = if ($existing) { $existing.TrimEnd() + "`r`n`r`n" + $block } else { $block }
  Write-TextFile -Path $path -Content $content -DryRun:$DryRun
}

function Write-McpConfigs {
  param(
    [string]$RepoPath,
    [string[]]$Ides,
    [hashtable]$Vars,
    [switch]$DryRun
  )
  $merged = Merge-McpJsonTemplates -HubPath $Vars['HUB'] -Vars $Vars
  if ([string]::IsNullOrWhiteSpace($Vars['CONTEXT7_API_KEY'])) {
    $ctx = $merged.mcpServers['context7']
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
  $json = $merged | ConvertTo-Json -Depth 10
  $vscode = @{ servers = $merged.mcpServers } | ConvertTo-Json -Depth 10

  foreach ($ide in $Ides) {
    switch ($ide) {
      'Cursor' {
        $path = Join-Path $RepoPath '.cursor\mcp.json'
        Write-TextFile -Path $path -Content $json -DryRun:$DryRun
      }
      'VSCode' {
        $path = Join-Path $RepoPath '.vscode\mcp.json'
        Write-TextFile -Path $path -Content $vscode -DryRun:$DryRun
      }
      'Kiro' {
        $path = Join-Path $RepoPath '.kiro\settings\mcp.json'
        Write-TextFile -Path $path -Content $json -DryRun:$DryRun
      }
      'Qoder' {
        $path = Join-Path $RepoPath '.qoder\mcp.json'
        Write-TextFile -Path $path -Content $json -DryRun:$DryRun
      }
      'OpenCode' {
        # Project config lives at <repo>\opencode.json (opencode.ai/docs/config),
        # and "mcp" is a flat map of servers (opencode.ai/docs/mcp-servers).
        $ocServers = ConvertTo-OpenCodeMcpServers -Servers $merged.mcpServers
        Write-OpenCodeConfig -RepoPath $RepoPath -McpServers $ocServers -DryRun:$DryRun
      }
      'Antigravity' {
        # Antigravity (IDE/CLI) reads workspace MCP config from .agents\mcp_config.json
        # (global fallback is ~/.gemini/config/mcp_config.json). It does NOT use
        # a project-level ".antigravity" folder for MCP.
        $path = Join-Path $RepoPath '.agents\mcp_config.json'
        Write-TextFile -Path $path -Content $json -DryRun:$DryRun
      }
      'Claude' {
        # Claude Code project MCP is <repo>\.mcp.json (code.claude.com/docs/en/mcp).
        $path = Join-Path $RepoPath '.mcp.json'
        Write-TextFile -Path $path -Content $json -DryRun:$DryRun
      }
      'Codex' {
        # Per-project .codex\config.toml so cwd of code-review-graph is this repo.
        # Omit "type": Codex McpServerConfig does not use that JSON field.
        $codexToml = ConvertTo-TomlMcp -Servers $merged.mcpServers -SkipProperties @('type')
        Write-CodexProjectConfig -RepoPath $RepoPath -Toml $codexToml -DryRun:$DryRun
      }
      'Devin' {
        # Devin CLI (v3000.3+) reads .devin\mcp_config.json (docs.devin.ai
        # cli/extensibility/mcp/configuration). Older .devin\mcp.json is leftover.
        $path = Join-Path $RepoPath '.devin\mcp_config.json'
        Write-TextFile -Path $path -Content $json -DryRun:$DryRun
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
<!-- Point to AGENTS.md - full stack guides live in D:\IA\agents skills (on demand). -->
See **AGENTS.md**. Load stack skills from the linked `D:\IA\agents` instead of duplicating guides here.
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
``D:\IA\agents`` skills (junctions under ``.kiro/skills``); load them on demand
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
  foreach ($fr in $fatRules) {
    if (-not (Test-Path $fr)) { continue }
    if ($DryRun) { Write-Host "  [dry] remove fat rule $(Split-Path $fr -Leaf)"; continue }
    Remove-Item $fr -Force
    Write-Host "  removed fat rule $(Split-Path $fr -Leaf)"
  }
}

function Remove-LegacyAgentPaths {
  # Cleans up artifacts written by older versions of this script that used
  # incorrect paths for Antigravity/OpenCode. Opt-in via -MigrateLegacyPaths
  # because it deletes files (reversible: this script regenerates them).
  param([string]$RepoPath, [switch]$DryRun)
  $legacy = @(
    (Join-Path $RepoPath '.antigravity\mcp.json'),
    (Join-Path $RepoPath '.antigravity\.antigravityrules'),
    (Join-Path $RepoPath '.antigravity\skills'),
    (Join-Path $RepoPath '.opencode\opencode.json'),
    (Join-Path $RepoPath '.devin\mcp.json'),
    (Join-Path $RepoPath '.gemini\GEMINI.md'),
    (Join-Path $RepoPath '.codex\claude')
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
    # Codex project layer maps .codex\ to .codex\skills (also reads .agents\skills).
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

if ($Roots.Count -eq 0) {
  $defaultSistemas = 'D:\SISTEMAS'
  if ($catalog.roots -and $catalog.roots.Count -gt 0) {
    $Roots = @($catalog.roots | ForEach-Object { Join-Path $defaultSistemas $_ } | Where-Object { Test-Path $_ })
  }
  if ($Roots.Count -eq 0) {
    # Fallback for legacy catalogs without roots
    if (Test-Path $defaultSistemas) {
      $Roots = @(
        (Join-Path $defaultSistemas 'ERPCLASS'),
        (Join-Path $defaultSistemas 'NFECLASS'),
        (Join-Path $defaultSistemas 'MOBICLASS')
      ) | Where-Object { Test-Path $_ }
    } else {
      $parent = Split-Path -Parent $HubPath
      $Roots = @(
        (Join-Path $parent 'ERPCLASS'),
        (Join-Path $parent 'NFECLASS'),
        (Join-Path $parent 'MOBICLASS')
      ) | Where-Object { Test-Path $_ }
    }
  }
}
$families = @{}
foreach ($prop in $catalog.families.PSObject.Properties) {
  $families[$prop.Name] = $prop.Value
}

$commonSkills = @()
if ($catalog.PSObject.Properties.Name -contains 'commonSkills') {
  $commonSkills = @($catalog.commonSkills)
}
Ensure-VendorSkillMirrors -HubPath $HubPath -SkillNames $commonSkills -DryRun:$DryRun
$allowedIdes = @($catalog.ides)
$qoderOptIn = [bool]$catalog.qoderOptIn
$detected = Get-DetectedIdes -Override $Ides -Allowed $allowedIdes -IncludeQoder:($IncludeQoder -or $qoderOptIn)
if ($detected.Count -eq 0) { Write-Warning 'No allowed IDEs detected. Use -Ides to force or update catalog ides list.' }

$python = Find-PythonExe
$crgPython = $python
if (-not $SkipCodeReviewGraph) {
  $crgPython = Get-CodeReviewGraphPython -HubPath $HubPath -SystemPython $python -DryRun:$DryRun
}
$context7ApiKey = $env:CONTEXT7_API_KEY
if ([string]::IsNullOrWhiteSpace($context7ApiKey)) {
  Write-Warning 'CONTEXT7_API_KEY not set; context7 MCP will run with public rate limits (get a key at context7.com/dashboard).'
  $context7ApiKey = ''
}
$mcpBaseVars = @{
  PYTHON = $crgPython
  HUB = $HubPath
  CONTEXT7_API_KEY = $context7ApiKey
}

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
    # skip non-repos without AGENTS and without src/source
    $looksLikeProject = (Test-Path (Join-Path $proj.FullName 'AGENTS.md')) -or
      (Test-Path (Join-Path $proj.FullName 'src')) -or
      (Test-Path (Join-Path $proj.FullName 'source')) -or
      (Test-Path (Join-Path $proj.FullName 'package.json')) -or
      (Test-Path (Join-Path $proj.FullName '.git'))
    if (-not $looksLikeProject) { return }

    $family = Get-ProjectFamily -Name $proj.Name -Families $families
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
    Write-McpConfigs -RepoPath $proj.FullName -Ides $detected -Vars $mcpVars -DryRun:$DryRun
    Write-PointerRules -RepoPath $proj.FullName -HubPath $HubPath -FamilyCfg $cfg -Ides $detected -DryRun:$DryRun
    Write-CopilotPointer -RepoPath $proj.FullName -HubPath $HubPath -Family $family -DryRun:$DryRun
    Write-AntigravityPointer -RepoPath $proj.FullName -HubPath $HubPath -Ides $detected -DryRun:$DryRun
    Write-KiroSteeringPointer -RepoPath $proj.FullName -ProjectName $proj.Name -Ides $detected -DryRun:$DryRun
    Remove-FatAlwaysOnRules -RepoPath $proj.FullName -DryRun:$DryRun

    if (-not $SkipCodeReviewGraph) {
      Ensure-CodeReviewGraphBuilt -RepoPath $proj.FullName -Skills @($cfg.skills) -PythonExe $crgPython -Force:$ForceCodeReviewGraphBuild -DryRun:$DryRun
    }

    if ($WriteAgents -or $ForceAgents) {
      $tpl = Join-Path $HubPath "templates\agents\$($cfg.agentsTemplate)"
      Write-AgentsFile -RepoPath $proj.FullName -ProjectName $proj.Name -TemplatePath $tpl -Force:$ForceAgents -DryRun:$DryRun
      Write-SlimStubs -RepoPath $proj.FullName -Ides $detected -DryRun:$DryRun
    }

    if ($RemoveUnusedIdeFolders) {
      $toRemove = @($catalog.unusedIdeFolders)
      Remove-UnusedIdeFolders -RepoPath $proj.FullName -Folders $toRemove -DryRun:$DryRun
    }
    if ($MigrateLegacyPaths) {
      Remove-LegacyAgentPaths -RepoPath $proj.FullName -DryRun:$DryRun
    }
    $stats.linked++
  }
}

# Convert Cursor hooks from .sh to .ps1 for Windows compatibility
$cursorHooksDir = Join-Path $env:USERPROFILE '.cursor\hooks'
if ((Test-Path $cursorHooksDir) -and $detected -contains 'Cursor') {
  Write-Host "`nConverting Cursor hooks to PowerShell..."

  # crg-session-start
  $shPath = Join-Path $cursorHooksDir 'crg-session-start.sh'
  $ps1Path = Join-Path $cursorHooksDir 'crg-session-start.ps1'
  if ((Test-Path $shPath) -and -not (Test-Path $ps1Path)) {
    $content = @'
# code-review-graph: show graph status on session start (Cursor hook)
# Fails gracefully — never blocks the editor.

$ErrorActionPreference = 'SilentlyContinue'
$null = $input
try {
    $output = & code-review-graph status 2>&1 | Out-String
} catch {
    $output = "graph not built yet"
}
$response = @{ message = $output.Trim(); passed = $true } | ConvertTo-Json -Compress
Write-Output $response
exit 0
'@
    if (-not $DryRun) {
      Set-Content -Path $ps1Path -Value $content -Encoding UTF8
      Remove-Item $shPath -Force
      Write-Host "  converted crg-session-start.sh -> .ps1"
    }
  }

  # crg-update
  $shPath = Join-Path $cursorHooksDir 'crg-update.sh'
  $ps1Path = Join-Path $cursorHooksDir 'crg-update.ps1'
  if ((Test-Path $shPath) -and -not (Test-Path $ps1Path)) {
    $content = @'
# code-review-graph: auto-update graph after file edits (Cursor hook)
# Fails gracefully — never blocks the editor.

$ErrorActionPreference = 'SilentlyContinue'
$null = $input
try {
    $output = & code-review-graph update --skip-flows 2>&1
} catch {
    $output = ""
}
$response = @{ message = 'graph updated'; passed = $true } | ConvertTo-Json -Compress
Write-Output $response
exit 0
'@
    if (-not $DryRun) {
      Set-Content -Path $ps1Path -Value $content -Encoding UTF8
      Remove-Item $shPath -Force
      Write-Host "  converted crg-update.sh -> .ps1"
    }
  }

  # crg-pre-commit
  $shPath = Join-Path $cursorHooksDir 'crg-pre-commit.sh'
  $ps1Path = Join-Path $cursorHooksDir 'crg-pre-commit.ps1'
  if ((Test-Path $shPath) -and -not (Test-Path $ps1Path)) {
    $content = @'
# code-review-graph: detect changes before git commit (Cursor hook)
# Fails gracefully — never blocks the editor.

$ErrorActionPreference = 'SilentlyContinue'
$null = $input
try {
    $output = & code-review-graph detect-changes --brief 2>&1 | Out-String
} catch {
    $output = ""
}
$response = @{ message = $output.Trim(); passed = $true } | ConvertTo-Json -Compress
Write-Output $response
exit 0
'@
    if (-not $DryRun) {
      Set-Content -Path $ps1Path -Value $content -Encoding UTF8
      Remove-Item $shPath -Force
      Write-Host "  converted crg-pre-commit.sh -> .ps1"
    }
  }
}

Write-Host "`nDone. Projects: $($stats.projects)"
Write-Host "Tip: commit slim AGENTS.md per repo; junctions are local (re-run this script on each machine)."
