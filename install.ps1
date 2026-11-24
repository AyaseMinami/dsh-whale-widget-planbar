<#
.SYNOPSIS
  一条命令装上「订阅额度卡片（planbar2）」补丁；必要时先安装上游 dsh-whale-widget 0.4.2。

.DESCRIPTION
  步骤：
    1. 解析 DSH_HOME：-DshHome > $env:DSH_HOME > $HOME/.dsh
    2. 检查 <DSH_HOME>/profiles/<Profile>/node_modules/dsh-whale-widget 是否存在
       不存在就调用 dsh CLI 安装上游 0.4.2（dsh 需在 PATH，或用 -DshCmd 指定）
    3. 校验已装版本；不是 0.4.2 时默认停止（-Force 可继续，但锚点可能匹配失败）
    4. 调用 apply-planbar.ps1 打补丁

  -Restore 不装补丁，改为重装上游 0.4.2（等于回滚）。

  需要 PowerShell 7（pwsh）。

.PARAMETER DshHome
  DSH_HOME。缺省依次取 $env:DSH_HOME、$HOME/.dsh。

.PARAMETER Profile
  DSH profile 名，默认 desktop。

.PARAMETER Version
  上游版本，默认 0.4.2（本补丁的锚点就是按这个版本写的）。

.PARAMETER DshCmd
  dsh 可执行文件的完整路径（PATH 里没有 dsh 时用）。

.PARAMETER Restore
  回滚：重装 dsh-whale-widget@<Version>，覆盖掉已打的补丁。

.PARAMETER Force
  已装版本不是 <Version> 时仍然继续（默认会停下）。

.EXAMPLE
  pwsh -File .\install.ps1

.EXAMPLE
  pwsh -File .\install.ps1 -DshHome "<你的 DSH_HOME>"

.EXAMPLE
  pwsh -File .\install.ps1 -Restore
#>
[CmdletBinding()]
param(
  [string]$DshHome = '',
  [string]$Profile = 'desktop',
  [string]$Version = '0.4.2',
  [string]$DshCmd = '',
  [switch]$Restore,
  [switch]$Force
)

$ErrorActionPreference = 'Stop'
$here = Split-Path -Parent $MyInvocation.MyCommand.Path

function Resolve-DshHome {
  param([string]$Explicit)
  if ($Explicit) { return $Explicit }
  if ($env:DSH_HOME) { return $env:DSH_HOME }
  if ($HOME) { return (Join-Path $HOME '.dsh') }
  return ''
}

function Resolve-DshCmd {
  param([string]$Explicit)
  if ($Explicit) {
    if (Test-Path -LiteralPath $Explicit) { return $Explicit }
    $c = Get-Command $Explicit -ErrorAction SilentlyContinue
    if ($c) { return $c.Source }
    throw "指定的 -DshCmd 不存在：$Explicit"
  }
  $c = Get-Command dsh -ErrorAction SilentlyContinue
  if ($c) { return $c.Source }
  return ''
}

function Install-Upstream {
  param([string]$DshCmdPath, [string]$Prof)
  $hint = "dsh plugin --profile $Prof add dsh-whale-widget@$Version"
  if (-not $DshCmdPath) {
    throw "找不到 dsh CLI，无法自动安装上游插件。`n请先手动执行：`n  $hint`n或重跑本脚本时加 -DshCmd <dsh.exe 完整路径>。"
  }
  Write-Host "安装上游插件：$hint"
  & $DshCmdPath plugin --profile $Prof add "dsh-whale-widget@$Version"
  if ($LASTEXITCODE -ne 0) { throw "dsh plugin add 失败（exit $LASTEXITCODE）；请手动执行上面的命令。" }
}

$DshHome = Resolve-DshHome -Explicit $DshHome
if (-not $DshHome) { throw '找不到 DSH_HOME：请用 -DshHome 指定，或设置环境变量 DSH_HOME。' }
if (-not (Test-Path -LiteralPath $DshHome)) { throw "DSH_HOME 不存在：$DshHome" }

$profileDir = Join-Path $DshHome "profiles\$Profile"
if (-not (Test-Path -LiteralPath $profileDir)) {
  throw "找不到 profile 目录：$profileDir`n可用 -Profile 指定别的 profile，或检查 -DshHome 是否正确。"
}

$pluginDir = Join-Path $profileDir 'node_modules\dsh-whale-widget'
$target = Join-Path $pluginDir 'assets\whale-widget.js'
$pkgPath = Join-Path $pluginDir 'package.json'
$dshCmdPath = Resolve-DshCmd -Explicit $DshCmd

if ($Restore) {
  Install-Upstream -DshCmdPath $dshCmdPath -Prof $Profile
  Write-Host '已重装上游版本，补丁已移除。刷新 DSH 界面即可。'
  return
}

if (-not (Test-Path -LiteralPath $target)) {
  Install-Upstream -DshCmdPath $dshCmdPath -Prof $Profile
  if (-not (Test-Path -LiteralPath $target)) {
    throw "安装后仍找不到：$target`n请检查 profile 名与 npm 安装是否成功。"
  }
}

$installedVersion = $null
if (Test-Path -LiteralPath $pkgPath) {
  $installedVersion = (Get-Content -LiteralPath $pkgPath -Raw -Encoding utf8 | ConvertFrom-Json).version
}
if ($installedVersion -and $installedVersion -ne $Version) {
  if (-not $Force) {
    throw "当前 dsh-whale-widget 是 $installedVersion，本补丁按 $Version 编写。`n先装回 $Version：`n  dsh plugin --profile $Profile add dsh-whale-widget@$Version`n或加 -Force 强行尝试（锚点不匹配会安全失败）。"
  }
  Write-Warning "版本是 $installedVersion（不是 $Version），继续尝试；锚点不匹配会失败。"
}

& (Join-Path $here 'apply-planbar.ps1') -Target $target -DshHome $DshHome
if (-not $?) { throw 'apply-planbar.ps1 执行失败，见上面的报错。' }

Write-Host ''
Write-Host "目标 profile：$Profile（$DshHome）"
Write-Host '下一步：刷新 DSH 界面 → 点小鲸鱼 → ☰，底部版本号应显示 v0.4.2+planbar2。'
Write-Host '回滚：pwsh -File .\install.ps1 -Restore'
