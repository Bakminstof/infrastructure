<#
.SYNOPSIS
  Обновление бинарников Salt Minion.
.DESCRIPTION
  Скачивает последнюю версию установщика Salt.
#>

# === Strict & Safe Mode ===
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "Continue"
$InformationPreference = "Continue"

# === Импорт утилит ===
$libsRoot = Join-Path $PSScriptRoot "..\..\Libs\PS" -Resolve
$scriptsRoot = Join-Path $PSScriptRoot "..\..\Scripts" -Resolve
$binariesDir = Join-Path $PSScriptRoot "..\..\Binaries" -Resolve

Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force

$githubLatestVersinGetter = Join-Path $scriptsRoot "GitHub/Get-GitHubLatestVersion.ps1"

$saltRepoName = "saltstack/salt"
$saltBinariesDir = Join-Path $binariesDir "Salt"
$saltMinionPath = Join-Path $saltBinariesDir "salt-minion-installer.exe"

$latestVersion = (. $githubLatestVersinGetter $saltRepoName -Quiet).Trim()
$latestVersionNum = $latestVersion.Replace("v", "")

$saltMinionUrl = "https://github.com/$saltRepoName/releases/download/$latestVersion/Salt-Minion-$latestVersionNum-Py3-AMD64-Setup.exe"

Write-LogMessage "Последняя версия: $latestVersion"

# === Скачиваем установщик ===
Write-LogMessage "Скачиваю обновление: $saltMinionUrl"
Invoke-WebRequest -Uri $saltMinionUrl -OutFile $saltMinionPath -UseBasicParsing -ErrorAction Stop
Write-LogMessage "Обновлено: $saltMinionPath"
Write-LogMessage "=== Обновление Salt Minion успешно завершено ==="
