#Requires -Version 5.1
# 权威副本：D:\Scoop\buckets\dsh\scripts\scoop-bucket-guard.ps1（CI 用这份，改这里再同步镜像）
# 同步镜像：D:\USER_ENV\.dsh\scripts\scoop-bucket-guard.ps1
<#
.SYNOPSIS
  dsh bucket 巡检：找出上游已发版但 bucket 没跟上的清单，并对 manifest 做形态体检。
.DESCRIPTION
  两类检查：
    1) 同步性：对每个 manifest 跑 scoop checkver（不写文件），输出 autoupdate available 即为落后；
    2) 形态：顶层 url 含 $version、url 数组与 hash 数量不等、checkver.script 缺 regex、
       autoupdate.hash 写成字面 sha256 —— 这四类都会让 autoupdate 静默失败或报错。
  退出码：0 = 全部最新且无形态问题；1 = 有落后/报错/形态 FAIL；2 = 巡检自身失败。
.PARAMETER BucketDir
  bucket 目录（含 json 的那层），默认 D:\Scoop\buckets\dsh\bucket。
.PARAMETER App
  只查指定清单（可多个，不带 .json）。
.PARAMETER Fix
  对落后的清单执行 checkver -Update（会改写文件）。
.PARAMETER SkipForm
  跳过形态体检，只查同步性。
.PARAMETER FormOnly
  只做形态体检，完全不联网、不跑 checkver。
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

function Invoke-Checkver([string]$Name, [switch]$Update) {
  $prev = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    if ($Update) {
      $raw = & $script:Checkver -App $Name -Dir $script:BucketDir -Update 2>&1
    } else {
      $raw = & $script:Checkver -App $Name -Dir $script:BucketDir 2>&1
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
  catch { [void]$issues.Add('FAIL JSON 解析失败'); return $issues }
  if ($j.architecture) {
    foreach ($a in @($j.architecture.PSObject.Properties.Name)) {
      $node = $j.architecture.$a
      $u = @($node.url | Where-Object { $_ })
      $h = @($node.hash | Where-Object { $_ })
      foreach ($one in $u) {
        if ($one -match '[\$](version|match)') {
          [void]$issues.Add('FAIL architecture.' + $a + '.url 含 $version/$match：顶层不替换，必须写死版本')
        }
      }
      if ($u.Count -gt 1 -and $h.Count -eq 1) {
        [void]$issues.Add('FAIL architecture.' + $a + '：' + $u.Count + ' 个 url 但只有 1 个 hash')
      }
      if ($u.Count -gt 1 -and $h.Count -gt 1 -and $u.Count -ne $h.Count) {
        [void]$issues.Add('FAIL architecture.' + $a + '：url 与 hash 数量不等')
      }
    }
  }
  $cv = $j.checkver
  if (-not $cv) { [void]$issues.Add('WARN 没有 checkver：bot 永远不跟进') }
  elseif ($cv -isnot [string]) {
    if ($cv.script -and -not $cv.regex) { [void]$issues.Add('FAIL checkver.script 缺 checkver.regex') }
    if ($cv.github -and -not $cv.regex -and $cv.script) { [void]$issues.Add('WARN checkver 同时给 github 与 script') }
  }
  $au = $j.autoupdate
  if ($au) {
    foreach ($h in @($au.hash)) {
      if ($h -is [string] -and $h -match '^[a-fA-F0-9]{64}$') {
        [void]$issues.Add('FAIL autoupdate.hash 是字面 sha256：会被当成 hash 模板 URL，报无效 URI；应省略或写 {url,regex}')
      }
    }
    $txt = ($au | ConvertTo-Json -Depth 12 -Compress)
    if ($txt -notmatch '"url"') { [void]$issues.Add('WARN autoupdate 里没有 url：版本更新不会改下载地址') }
  } elseif ($cv) {
    [void]$issues.Add('WARN 有 checkver 没 autoupdate：bot 只报版本不改清单')
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
  [Console]::Error.WriteLine('找不到 scoop checkver: ' + $script:Checkver)
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
  if (-not (Test-Path -LiteralPath $file)) { [void]$errors.Add($n + '  清单不存在'); continue }
  $checked++
  if ($FormOnly) {
    if (-not $SkipForm) { foreach ($i in (Test-ManifestForm $file)) { [void]$formIssues.Add($n + ': ' + [string]$i) } }
    continue
  }
  $text = Invoke-Checkver $n
  $isOutdated = $text -match 'autoupdate available'
  $hasError = ($text -match '(?m)^\s*ERROR') -or ($text -match 'EXCEPTION') -or ($text -match 'Could not')
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

Write-Host ('检查清单数: ' + $checked)
if ($outdated.Count -gt 0) {
  Write-Host ''
  Write-Host '[落后] 上游已有新版但 bucket 未跟进：' -ForegroundColor Yellow
  foreach ($x in $outdated) { Write-Host ('  - ' + $x) }
} else { Write-Host '[落后] 无' -ForegroundColor Green }
if ($errors.Count -gt 0) {
  Write-Host ''
  Write-Host '[报错] checkver 本身失败（多为上游形态变化）：' -ForegroundColor Red
  foreach ($x in $errors) { Write-Host ('  - ' + $x) }
}
if ($formIssues.Count -gt 0) {
  Write-Host ''
  Write-Host '[形态] 会让 autoupdate 失败或空转的写法：' -ForegroundColor Magenta
  foreach ($x in $formIssues) { Write-Host ('  - ' + $x) }
}

if ($Fix) {
  $targets = New-Object System.Collections.ArrayList
  foreach ($x in $outdated) { [void]$targets.Add((([string]$x) -split '  ')[0]) }
  if ($targets.Count -gt 0) {
    Write-Host ''
    Write-Host '[Fix] 逐个 checkver -Update ...'
    foreach ($n in $targets) {
      Write-Host ('  -> ' + $n)
      $r = Invoke-Checkver $n -Update
      if ($r -match 'ERROR|EXCEPTION|Could not') {
        $e = (@($r -split '\r?\n') | Where-Object { $_ -match 'ERROR|Exception|Could not' } | Select-Object -First 1)
        Write-Host ('     FAIL: ' + ([string]$e).Trim()) -ForegroundColor Red
      } else { Write-Host '     OK' -ForegroundColor Green }
    }
  }
}

if ($outdated.Count -gt 0 -or $errors.Count -gt 0 -or $formIssues.Count -gt 0) { exit 1 }
exit 0
