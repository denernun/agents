# Shared read/write and ownership helpers. No work is performed on import.
. (Join-Path $PSScriptRoot 'AgentHub.Ecc.ps1')
$HubPythonExe = $null
function Get-HubPython {
  # The Windows Store app-alias shim (…\WindowsApps\python.exe) forwards to the
  # Python Manager runtime, which can be momentarily unavailable while the
  # package updates and then fails with "Fatal Python error: Failed to import
  # encodings module". Prefer a real interpreter when one is installed.
  if ($script:HubPythonExe) { return $script:HubPythonExe }
  $paths = @()
  foreach ($name in @('python', 'python3')) {
    $paths += @(Get-Command $name -All -ErrorAction SilentlyContinue |
      Where-Object { $_.Path -and $_.Path -notmatch '\\WindowsApps\\' } |
      ForEach-Object { $_.Path })
  }
  $paths += @(Get-Command 'python' -All -ErrorAction SilentlyContinue | ForEach-Object { $_.Path })
  $resolved = $paths | Where-Object { $_ } | Select-Object -First 1
  if (-not $resolved) { throw 'Python 3 not found; agenthub_config.py cannot run.' }
  $script:HubPythonExe = $resolved
  return $resolved
}

function Invoke-HubConfig {
  param([hashtable]$Request)
  $Request.hub = $HubPath
  $python = Get-HubPython
  $script = Join-Path $PSScriptRoot 'agenthub_config.py'
  # An interpreter that fails to start prints nothing to stdout; a real config
  # error always prints one JSON object. Retry only the former: the write is
  # deterministic, so re-running it is safe.
  for ($attempt = 1; ; $attempt++) {
    $result = ($Request | ConvertTo-Json -Depth 50 -Compress) | & $python $script
    if ($LASTEXITCODE -eq 0) { break }
    if (($result -join '').Trim() -or $attempt -ge 2) {
      throw "Configuration update failed for $($Request.path); file preserved. Check syntax and manual changes."
    }
    Start-Sleep -Milliseconds 250
  }
  $response = $result | ConvertFrom-Json
  foreach ($message in @($response.messages)) { Write-Warning $message }
  if ($response.changed) { Write-Host "  $(if ($Request.dry) {'[dry] '})update $($Request.path)" }
}

function Test-HubOwnedLink {
  param([string]$Path, [string]$HubPath)
  $item = Get-Item -LiteralPath $Path -Force -ErrorAction SilentlyContinue
  if (-not $item) { return $false }
  if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) {
    foreach ($target in @($item.Target)) {
      if (-not [IO.Path]::IsPathRooted($target)) { $target = Join-Path $item.Parent.FullName $target }
      $absolute = [IO.Path]::GetFullPath($target)
      if ($absolute.StartsWith([IO.Path]::GetFullPath($HubPath).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    }
  } elseif (Test-Path -LiteralPath (Join-Path $Path '.agenthub-managed')) { return $true }
  return $false
}

function Remove-HubLink {
  param([string]$Path, [string]$Root, [string]$HubPath, [switch]$DryRun)
  $absolute = [IO.Path]::GetFullPath($Path)
  $boundary = [IO.Path]::GetFullPath($Root).TrimEnd('\','/') + [IO.Path]::DirectorySeparatorChar
  if (-not $absolute.StartsWith($boundary, [StringComparison]::OrdinalIgnoreCase)) { throw "Path outside cleanup root: $Path" }
  if (-not (Test-HubOwnedLink -Path $Path -HubPath $HubPath)) { return }
  if ($DryRun) { Write-Host "  [dry] unlink $Path"; return }
  $item = Get-Item -LiteralPath $Path -Force
  if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { [IO.Directory]::Delete($absolute) }
  else { Remove-Item -LiteralPath $absolute -Recurse -Force }
}

function Test-HubSkill {
  param([string]$Path)
  $file = Join-Path $Path 'SKILL.md'
  if (-not (Test-Path -LiteralPath $file -PathType Leaf)) { return $false }
  $text = Get-Content -LiteralPath $file -Raw -Encoding UTF8
  if ($text -notmatch '\A---\r?\n(?<meta>[\s\S]*?)\r?\n---\r?\n(?<body>[\s\S]+)') { return $false }
  $meta = $Matches.meta; $body = $Matches.body
  if ([string]::IsNullOrWhiteSpace($body)) { return $false }
  if ($meta -notmatch '(?m)^name:\s*[''\"]?([a-z0-9][a-z0-9-]{0,63})[''\"]?\s*$') { return $false }
  if ($meta -notmatch '(?m)^description:\s*\S+') { return $false }
  if ($meta -match '(?m)^description:\s*[>|][-+]?\s*$' -and $meta -notmatch '(?m)^\s+\S+') { return $false }
  return $true
}

function Write-HubText {
  param([string]$Path, [string]$Content, [switch]$DryRun)
  Invoke-HubConfig @{path=$Path; format='text'; text=$Content; adopt=[bool]$AdoptLegacyConfigs; dry=[bool]$DryRun}
}

function Remove-HubIdeArtifacts {
  param([string]$RepoPath, [string]$Ide, [string[]]$ActiveIdes = @(), [switch]$DryRun)
  $registry = Get-IdeRegistry
  if (-not $registry.Contains($Ide)) { return }
  $entry = $registry[$Ide]
  # .agents/skills is shared by Codex and Antigravity: only clear it when
  # neither of them is still active.
  $sharedInUse = $entry.Skills -eq '.agents/skills' -and @($ActiveIdes | Where-Object { $_ -in @('Codex','Antigravity') }).Count -gt 0
  if (-not $sharedInUse) {
    $root = Join-Path $RepoPath $entry.Skills
    foreach ($item in Get-ChildItem -LiteralPath $root -Directory -Force -ErrorAction SilentlyContinue) {
      Remove-HubLink -Path $item.FullName -Root $RepoPath -HubPath $HubPath -DryRun:$DryRun
    }
  }
  if ($Ide -eq 'Codex') {
    foreach ($item in Get-ChildItem -LiteralPath (Join-Path $RepoPath '.codex/skills') -Directory -Force -ErrorAction SilentlyContinue) {
      Remove-HubLink -Path $item.FullName -Root $RepoPath -HubPath $HubPath -DryRun:$DryRun
    }
  }
  $path = Join-Path $RepoPath $entry.Mcp
  if (Test-Path -LiteralPath $path) {
    $request = @{path=$path; remove=$true; dry=[bool]$DryRun}
    if ($entry.Property -eq 'toml') { $request.format='toml' } else { $request.property=$entry.Property }
    Invoke-HubConfig $request
  }
  # Cursor's rule files are whatever templates/rules currently holds, so they
  # are enumerated instead of listed: a hardcoded list went stale the moment a
  # family was added or removed (it still named the retired Delphi pointer).
  $cursorPointers = @('.cursorrules')
  foreach ($rule in Get-ChildItem -LiteralPath (Join-Path $HubPath 'templates\rules') -Filter '*.mdc' -File -ErrorAction SilentlyContinue) {
    $cursorPointers += ".cursor/rules/$($rule.Name)"
  }
  $pointers = @{
    Cursor = $cursorPointers
    Claude=@('CLAUDE.md'); VSCode=@('.github/copilot-instructions.md')
    Antigravity=@('.agents/rules/stack-pointer.md'); Kiro=@('.kiro/steering/stack-pointer.md')
  }
  if ($pointers.ContainsKey($Ide)) {
    foreach ($rel in $pointers[$Ide]) {
      $path = Join-Path $RepoPath $rel
      if (Test-Path -LiteralPath $path) { Invoke-HubConfig @{path=$path; format='text'; remove=$true; dry=[bool]$DryRun} }
    }
  }
}

function Import-HubFunctions {
  # Import definitions only, never execute installer setup or main loop.
  $tokens=$null; $errors=$null
  $ast=[Management.Automation.Language.Parser]::ParseFile((Join-Path $PSScriptRoot 'Install-AgentHub.ps1'), [ref]$tokens, [ref]$errors)
  if ($errors.Count) { throw 'Installer contains syntax errors' }
  foreach ($definition in $ast.FindAll({param($n) $n -is [Management.Automation.Language.FunctionDefinitionAst]}, $false)) {
    Set-Item -Path "Function:script:$($definition.Name)" -Value $definition.Body.GetScriptBlock()
  }
}
