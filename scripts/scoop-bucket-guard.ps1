#Requires -Version 5.1
# Canonical copy: D:\Scoop\buckets\dsh\scripts\scoop-bucket-guard.ps1 (CI uses this one; edit here, then sync the mirror)
# Mirror: D:\USER_ENV\.dsh\scripts\scoop-bucket-guard.ps1
<#
.SYNOPSIS
  dsh bucket guard: find manifests whose upstream released a newer version, and lint manifest shape.
.DESCRIPTION
  Two kinds of checks:
    1) sync: run scoop checkver per manifest (no writes); "autoupdate available" means outdated;
    2) shape: top-level url containing $version, url/hash count mismatch, checkver.script without regex,
       autoupdate.hash given as a literal sha256 -- all four silently break autoupdate.
  Exit: 0 = everything current and clean; 1 = outdated/error/shape issue; 2 = guard itself failed.
.PARAMETER BucketDir
  bucket directory (the folder holding the json files). Auto-detected: <repo>\bucket, else D:\Scoop\buckets\dsh\bucket.
.PARAMETER App
  Only check these manifests (no .json suffix).
.PARAMETER Fix
  Run checkver -Update for outdated manifests (rewrites files).
.PARAMETER SkipForm
  Skip the shape lint; sync only.
.PARAMETER FormOnly
  Shape lint only; fully offline, never runs checkver.
.EXAMPLE
  powershell -File scoop-bucket-guard.ps1
.EXAMPLE
  powershell -File scoop-bucket-guard.ps1 -App strata-hip -Fix
#>
[CmdletBinding()]
param(
  [string]$BucketDir = '',
  [string[]]$App,
  [switch]$Fix,
  [switch]$SkipForm,
  [switch]$FormOnly
)

try { [Console]::OutputEncoding = [Text.Encoding]::UTF8 } catch { }
$ErrorActionPreference = 'Stop'
$nl = [Environment]::NewLine

function Get-ScoopRoot {
  if ($env:SCOOP) { return $env:SCOOP }
  $home2 = [Environment]::GetFolderPath('UserProfile')
  $cfg = Join-Path $home2 '.config\scoop\config.json'
  if (Test-Path -LiteralPath $cfg) {
    try {
      $r = (Get-Content -LiteralPath $cfg -Raw | ConvertFrom-Json).rootPath
      if ($r) { return $r }
    } catch { }
  }
  return (Join-Path $home2 'scoop')
}

# scoop checkver prints through Write-Host (information stream): plain 2>&1 captures nothing,
# which makes every verdict look up-to-date. Redirect all streams with *>&1.
function Invoke-Checkver([string]$Name, [switch]$Update) {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    if ($Update) {
      $raw = & $script:Checkver -App $Name -Dir $script:BucketDir -Update *>&1
    } else {
      $raw = & $script:Checkver -App $Name -Dir $script:BucketDir *>&1
    }
    return ((@($raw) | ForEach-Object { [string]$_ }) -join $nl)
  } catch {
    return ('EXCEPTION: ' + $_.Exception.Message)
  } finally { $ErrorActionPreference = $prev }
}

function Test-ManifestForm([string]$Path) {
  $issues = New-Object System.Collections.ArrayList
  $j = $null
  try { $j = Get-Content -LiteralPath $Path -Raw -Encoding UTF8 | ConvertFrom-Json }
  catch { [void]$issues.Add('FAIL cannot parse JSON'); return $issues }
  if ($j.architecture) {
    foreach ($a in @($j.architecture.PSObject.Properties.Name)) {
      $node = $j.architecture.$a
      $u = @($node.url | Where-Object { $_ })
      $h = @($node.hash | Where-Object { $_ })
      foreach ($one in $u) {
        if ($one -match '[\$](version|match)') {
          [void]$issues.Add('FAIL architecture.' + $a + '.url contains $version/$match: top-level is never substituted, pin the version')
        }
      }
      if ($u.Count -gt 1 -and $h.Count -eq 1) {
        [void]$issues.Add('FAIL architecture.' + $a + ': ' + $u.Count + ' urls but only 1 hash')
      }
      if ($u.Count -gt 1 -and $h.Count -gt 1 -and $u.Count -ne $h.Count) {
        [void]$issues.Add('FAIL architecture.' + $a + ': url and hash counts differ')
      }
    }
  }
  $cv = $j.checkver
  if (-not $cv) { [void]$issues.Add('WARN no checkver: the bot will never bump this manifest') }
  elseif ($cv -isnot [string]) {
    if ($cv.script -and -not $cv.regex) { [void]$issues.Add('FAIL checkver.script without checkver.regex') }
    if ($cv.github -and -not $cv.regex -and $cv.script) { [void]$issues.Add('WARN checkver sets both github and script') }
  }
  $au = $j.autoupdate
  if ($au) {
    foreach ($h in @($au.hash)) {
      if ($h -is [string] -and $h -match '^[a-fA-F0-9]{64}$') {
        [void]$issues.Add('FAIL autoupdate.hash is a literal sha256: it is treated as a hash-template URL and fails with an invalid URI; omit it or use {url,regex}')
      }
    }
    $txt = ($au | ConvertTo-Json -Depth 12 -Compress)
    if ($txt -notmatch '"url"') { [void]$issues.Add('WARN autoupdate has no url: a version bump would not change the download address') }
  } elseif ($cv) {
    [void]$issues.Add('WARN checkver without autoupdate: the bot can only report the version, not bump the manifest')
  }
  return $issues
}

if (-not $BucketDir) {
  $repoBucket = Join-Path (Split-Path -Parent $PSScriptRoot) 'bucket'
  if (Test-Path -LiteralPath $repoBucket) { $BucketDir = $repoBucket } else { $BucketDir = 'D:\Scoop\buckets\dsh\bucket' }
}
$script:BucketDir = (Resolve-Path -LiteralPath $BucketDir).Path
$script:Checkver = ''
if ($env:SCOOP_HOME) {
  $homeCv = Join-Path $env:SCOOP_HOME 'bin\checkver.ps1'
  if (Test-Path -LiteralPath $homeCv) { $script:Checkver = $homeCv }
}
if (-not $script:Checkver) {
  $root = Get-ScoopRoot
  $script:Checkver = Join-Path $root 'apps\scoop\current\bin\checkver.ps1'
}
if (-not $FormOnly -and -not (Test-Path -LiteralPath $script:Checkver)) {
  [Console]::Error.WriteLine('cannot find scoop checkver: ' + $script:Checkver)
  exit 2
}

if ($App) { $names = $App }
else { $names = Get-ChildItem -LiteralPath $script:BucketDir -Filter *.json -File | ForEach-Object { $_.BaseName } | Sort-Object }

$outdated = New-Object System.Collections.ArrayList
$errors = New-Object System.Collections.ArrayList
$formIssues = New-Object System.Collections.ArrayList
$checked = 0

foreach ($n in $names) {
  $file = Join-Path $script:BucketDir ($n + '.json')
  if (-not (Test-Path -LiteralPath $file)) { [void]$errors.Add($n + '  manifest not found'); continue }
  $checked++
  if ($FormOnly) {
    if (-not $SkipForm) { foreach ($i in (Test-ManifestForm $file)) { [void]$formIssues.Add($n + ': ' + [string]$i) } }
    continue
  }
  $text = Invoke-Checkver $n
  $isOutdated = $text -match 'autoupdate available'
  $hasError = ($text -match '(?m)^\s*ERROR') -or ($text -match 'EXCEPTION') -or
    ($text -match 'Could not') -or ($text -match "couldn't match") -or ($text -match 'is not valid') -or
    ($text -match '\(404\)') -or ($text -match '\u672a\u627e\u5230')
  if ($isOutdated) {
    $line = (@($text -split '\r?\n') | Where-Object { $_ -match 'scoop version is' } | Select-Object -First 1)
    if (-not $line) { $line = 'version differs' }
    [void]$outdated.Add($n + '  ' + ([string]$line).Trim())
  }
  if ($hasError) {
    $e = (@($text -split '\r?\n') | Where-Object { $_ -match 'ERROR|Exception|Could not' } | Select-Object -First 1)
    [void]$errors.Add($n + '  ' + ([string]$e).Trim())
  }
  if (-not $SkipForm) {
    foreach ($i in (Test-ManifestForm $file)) { [void]$formIssues.Add($n + ': ' + [string]$i) }
  }
}

Write-Host ('checked manifests: ' + $checked)
if ($outdated.Count -gt 0) {
  Write-Host ''
  Write-Host '[outdated] upstream has a newer release:' -ForegroundColor Yellow
  foreach ($x in $outdated) { Write-Host ('  - ' + $x) }
} else { Write-Host '[outdated] none' -ForegroundColor Green }
if ($errors.Count -gt 0) {
  Write-Host ''
  Write-Host '[error] checkver itself failed (usually an upstream shape change):' -ForegroundColor Red
  foreach ($x in $errors) { Write-Host ('  - ' + $x) }
}
if ($formIssues.Count -gt 0) {
  Write-Host ''
  Write-Host '[shape] patterns that break or no-op autoupdate:' -ForegroundColor Magenta
  foreach ($x in $formIssues) { Write-Host ('  - ' + $x) }
}

if ($Fix) {
  $targets = New-Object System.Collections.ArrayList
  foreach ($x in $outdated) { [void]$targets.Add((([string]$x) -split '  ')[0]) }
  if ($targets.Count -gt 0) {
    Write-Host ''
    Write-Host '[Fix] running checkver -Update for each outdated manifest ...'
    foreach ($n in $targets) {
      Write-Host ('  -> ' + $n)
      $r = Invoke-Checkver $n -Update
      if ($r -match 'ERROR|EXCEPTION|Could not|couldn''t match|is not valid') {
        $e = (@($r -split '\r?\n') | Where-Object { $_ -match 'ERROR|Exception|Could not' } | Select-Object -First 1)
        Write-Host ('     FAIL: ' + ([string]$e).Trim()) -ForegroundColor Red
      } else { Write-Host '     OK' -ForegroundColor Green }
    }
  }
}

if ($outdated.Count -gt 0 -or $errors.Count -gt 0 -or $formIssues.Count -gt 0) { exit 1 }
exit 0
