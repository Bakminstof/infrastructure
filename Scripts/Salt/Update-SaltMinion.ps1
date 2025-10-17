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
$saltBinariesDir = Join-Path $binariesDir "Salt"

Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force
Import-Module (Join-Path $libsRoot "BinaryMetadata.psm1") -Force
Import-Module (Join-Path $libsRoot "DefaultConfig.psm1") -Force

# === Файл метаданных ===
$metadataFile = Join-Path $saltBinariesDir $DefaultBinaryMetadataFileName
$existingVersion = Get-BinaryVersion -FilePath $metadataFile

$githubLatestVersinGetter = Join-Path $scriptsRoot "GitHub/Get-GitHubLatestVersion.ps1"

$saltRepoName = "saltstack/salt"
$saltBinariesDir = Join-Path $binariesDir "Salt"
$saltMinionPath = Join-Path $saltBinariesDir "salt-minion-installer.exe"

$latestVersion = (. $githubLatestVersinGetter $saltRepoName -Quiet).Trim()
$latestVersionNum = $latestVersion.Replace("v", "")

$saltMinionUrl = "https://github.com/$saltRepoName/releases/download/$latestVersion/Salt-Minion-$latestVersionNum-Py3-AMD64-Setup.exe"

Write-LogMessage "Последняя версия: $latestVersion" -NoFileLog

if (-not (Test-Path $saltBinariesDir )) {
  Write-LogMessage "Создаю директорию: $saltBinariesDir" -NoFileLog
  New-Item -ItemType Directory -Path $saltBinariesDir -Force | Out-Null
}

if ($existingVersion -eq $latestVersion) {
  Write-LogMessage "Salt Minion уже актуален: $latestVersion" -NoFileLog
} else {
  Write-LogMessage "Скачиваю обновление: $saltMinionUrl" -NoFileLog
  Invoke-WebRequest -Uri $saltMinionUrl -OutFile $saltMinionPath -UseBasicParsing -ErrorAction Stop
  Write-LogMessage "Обновлено: $saltMinionPath" -NoFileLog

  Update-BinaryMetadata -FilePath $metadataFile -Name "salt-minion" -Version $latestVersion
  Write-LogMessage "Метаданные обновлены: $metadataFile" -NoFileLog
}
