<#
.SYNOPSIS
  把「订阅额度卡片（planbar2）」补丁打进 dsh-whale-widget 的客户端 bundle。

.DESCRIPTION
  默认目标是：
    $env:DSH_HOME\profiles\desktop\node_modules\dsh-whale-widget\assets\whale-widget.js

  幂等：已含补丁标记时直接退出；任一锚点找不到则报错退出（说明上游代码已变，
  需要人工核对，不要强行套用）。

  需要 PowerShell 7（pwsh）；脚本按 UTF-8 读写目标文件，保持原有换行风格。

.PARAMETER Target
  whale-widget.js 的绝对路径。给了就不再解析 DSH_HOME。

.PARAMETER DshHome
  DSH_HOME。缺省依次取 $env:DSH_HOME、$HOME/.dsh。

.EXAMPLE
  pwsh -File .\apply-planbar.ps1

.EXAMPLE
  pwsh -File .\apply-planbar.ps1 -Target "<插件目录>\assets\whale-widget.js"
#>
[CmdletBinding()]
param(
  [string]$Target = '',
  [string]$DshHome = ''
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$marker = '本地补丁（planbar）'
$expectedVersion = '0.4.2'

if (-not $DshHome) {
  if ($env:DSH_HOME) { $DshHome = $env:DSH_HOME }
  elseif ($HOME) { $DshHome = Join-Path $HOME '.dsh' }
}

if (-not $Target) {
  if (-not $DshHome) { throw '未指定 -Target，也找不到 DSH_HOME（可显式传 -DshHome 或 -Target）' }
  $Target = Join-Path $DshHome 'profiles\desktop\node_modules\dsh-whale-widget\assets\whale-widget.js'
}

if (-not (Test-Path -LiteralPath $Target)) {
  throw "找不到目标文件：$Target`n请先安装上游插件：dsh plugin --profile desktop add dsh-whale-widget@$expectedVersion"
}

$pkgPath = Join-Path (Split-Path (Split-Path $Target -Parent) -Parent) 'package.json'
if (Test-Path -LiteralPath $pkgPath) {
  try {
    $installedVersion = (Get-Content -LiteralPath $pkgPath -Raw -Encoding utf8 | ConvertFrom-Json).version
    if ($installedVersion -and $installedVersion -ne $expectedVersion) {
      Write-Warning "当前安装的是 dsh-whale-widget $installedVersion，本补丁按 $expectedVersion 编写；若锚点匹配失败属正常，请先核对上游改动。"
    }
  } catch {}
}

$text = Get-Content -LiteralPath $Target -Raw -Encoding utf8
if ($text.Contains($marker)) {
  Write-Host "已打过补丁，跳过：$Target"
  return
}

$pairsPath = Join-Path $here 'pairs.json'
if (-not (Test-Path -LiteralPath $pairsPath)) {
  throw "找不到 pairs.json（补丁片段）：$pairsPath"
}
$pairs = Get-Content -LiteralPath $pairsPath -Raw -Encoding utf8 | ConvertFrom-Json

# 文件用 CRLF 时，把补丁片段的 \n 也换成 \r\n，否则锚点匹配不上
$crlf = $text.Contains("`r`n")
$seen = @{}
$applied = 0
foreach ($p in $pairs) {
  $old = [string]$p.old
  $new = [string]$p.new
  if ($crlf) {
    $old = $old.Replace("`n", "`r`n")
    $new = $new.Replace("`n", "`r`n")
  }
  if ($seen.ContainsKey($old)) { continue }   # 同一片段出现两次（两个函数里一模一样）
  if (-not $text.Contains($old)) {
    $preview = $old.Substring(0, [Math]::Min(160, $old.Length))
    throw "锚点未找到，上游代码可能已变，需要人工核对：`n$preview"
  }
  $text = $text.Replace($old, $new)
  $seen[$old] = $true
  $applied++
}

Set-Content -LiteralPath $Target -Value $text -Encoding utf8NoBOM -NoNewline
Write-Host "已应用 $applied 个片段：$Target"

# 语法校验（找得到 node 才跑）
$nodePath = $null
$cmd = Get-Command node -ErrorAction SilentlyContinue
if ($cmd) { $nodePath = $cmd.Source }
if (-not $nodePath -and $DshHome) {
  $candidate = Join-Path $DshHome 'dsh-runtimes\dsh-primary-runtime\dependencies\node\bin\node.exe'
  if (Test-Path -LiteralPath $candidate) { $nodePath = $candidate }
}
if ($nodePath) {
  & $nodePath --check $Target
  if ($LASTEXITCODE -ne 0) { throw "node --check 失败（语法错误），请回滚：重装 dsh-whale-widget 或恢复备份" }
  Write-Host 'node --check 通过'
} else {
  Write-Host '未找到 node，跳过语法校验'
}

Write-Host '完成。刷新 DSH 界面（Ctrl+R / Ctrl+Shift+R）；仍显示旧版号时重启一次 DSH。'
