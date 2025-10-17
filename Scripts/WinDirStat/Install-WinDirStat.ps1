<#
.SYNOPSIS
  Тихая установка WinDirStat на Windows.
.DESCRIPTION
  Устанавливает WinDirStat из локального MSI-файла.
  Использует аргументы /quiet /passive /q /norestart и ведёт логирование.
#>

[CmdletBinding()]
param(
  [string]$BaseToolsDir = "C:\Tools",
  [switch]$SkipInstallCheck
)

# === Strict & Safe Mode ===
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# === Импорт утилит ===
$libsRoot = Join-Path $PSScriptRoot "..\..\Libs\PS" -Resolve
Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force
Import-Module (Join-Path $libsRoot "Common.psm1") -Force
Import-Module (Join-Path $libsRoot "AccessUtils.psm1") -Force

Confirm-RunAsAdmin

# === Пути ===
$binariesDir = Join-Path $PSScriptRoot "..\..\Binaries" -Resolve
$winDirStatDir = Join-Path $binariesDir "WinDirStat" -Resolve
$installerPath = Join-Path $winDirStatDir "WinDirStat-installer.msi"

if (-not (Test-Path $installerPath)) {
  throw "Файл установщика не найден: $installerPath"
}

# === Логи ===
$timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$hostname = $env:COMPUTERNAME
$logDir = Join-Path $PSScriptRoot "logs"
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

$global:logFile = Join-Path $logDir "$timestamp-$hostname.log"

Write-LogMessage "=== Установка WinDirStat ($hostname) ==="
Write-LogMessage "MSI: $installerPath"

# === Проверка существующей установки ===
$existing = Test-AppInstalled -AppName "WinDirStat"

if (-not $SkipInstallCheck -and $existing) {
  Write-LogMessage "WinDirStat уже установлен — пропускаю установку." "WARN"
  exit 0
}

# === Создание каталога ===
if (-not (Test-Path $BaseToolsDir)) {
  Write-LogMessage "Создаю директорию $BaseToolsDir"
  New-Item -ItemType Directory -Path $BaseToolsDir -Force | Out-Null
}

# === Установка ===
$installArgs = @(
  "/i `"$installerPath`"",
  "/quiet",
  "/passive",
  "/q",
  "/norestart",
  "/log `"$global:logFile`""
) -join ' '

Write-LogMessage "Запускаю установку WinDirStat"
Start-Process -FilePath "msiexec.exe" -ArgumentList $installArgs -Wait -PassThru | Out-Null

# === Проверка после установки ===
$installed = Test-AppInstalled -AppName "WinDirStat"

if ($installed) {
  Write-LogMessage "WinDirStat успешно установлен."
    
  if ($installed.PSObject.Properties.Name -contains 'DisplayVersion') {
    Write-LogMessage "Версия: $($installed.DisplayVersion)"
  } else {
    Write-LogMessage "Версия программы не указана в реестре."
  }
} else {
  Write-LogMessage "Ошибка: WinDirStat не найден после установки." "ERROR"
  exit 1
}

Write-LogMessage "=== Установка WinDirStat завершена успешно ==="