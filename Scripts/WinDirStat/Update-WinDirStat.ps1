<#
.SYNOPSIS
  Обновление бинарников WinDirStat.
.DESCRIPTION
  Скачивает последнюю версию установщика WinDirStat.
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
$windirstatBinariesDir = Join-Path $binariesDir "WinDirStat"

Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force
Import-Module (Join-Path $libsRoot "BinaryMetadata.psm1") -Force
Import-Module (Join-Path $libsRoot "DefaultConfig.psm1") -Force

# === Файл метаданных ===
$metadataFile = Join-Path $windirstatBinariesDir $DefaultBinaryMetadataFileName
$existingVersion = Get-BinaryVersion -FilePath $metadataFile

$githubLatestVersinGetter = Join-Path $scriptsRoot "GitHub/Get-GitHubLatestVersion.ps1"

$windirstatRepoName = "windirstat/windirstat"
$windirstatBinariesDir = Join-Path $binariesDir "WinDirStat"
$windirstatPath = Join-Path $windirstatBinariesDir "WinDirStat-installer.msi"

$latestVersion = (. $githubLatestVersinGetter $windirstatRepoName -Quiet).Trim()

$windirstatUrl = "https://github.com/$windirstatRepoName/releases/download/$latestVersion/WinDirStat-x64.msi"

Write-LogMessage "Последняя версия: $latestVersion" -NoFileLog

if (-not (Test-Path $windirstatBinariesDir )) {
  Write-LogMessage "Создаю директорию: $windirstatBinariesDir" -NoFileLog
  New-Item -ItemType Directory -Path $windirstatBinariesDir -Force | Out-Null
}

if ($existingVersion -eq $latestVersion) {
  Write-LogMessage "WinDirStat уже актуален: $latestVersion" -NoFileLog
} else {
  Write-LogMessage "Скачиваю обновление: $windirstatUrl" -NoFileLog
  Invoke-WebRequest -Uri $windirstatUrl -OutFile $windirstatPath -UseBasicParsing -ErrorAction Stop
  Write-LogMessage "Обновлено: $windirstatPath" -NoFileLog

  Update-BinaryMetadata -FilePath $metadataFile -Name "WinDirStat" -Version $latestVersion
  Write-LogMessage "Метаданные обновлены: $metadataFile" -NoFileLog
}
