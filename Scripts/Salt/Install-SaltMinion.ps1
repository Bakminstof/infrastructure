<#
.SYNOPSIS
  Установка и настройка Salt Minion на Windows.
.DESCRIPTION
  Скачивает и устанавливает Salt Minion в C:\Tools\Salt.
  Настраивает Master, ID, запускает службу и ведёт лог.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$MasterAddress,             # IP или DNS мастера
    [string]$MinionId = $env:COMPUTERNAME,
    [string]$BaseToolsDir = "C:\Tools",
    [string]$SaltInstallDir = "$BaseToolsDir\Salt",
    [string]$DownloadDir = "$env:TEMP",
    [switch]$SkipInstallCheck
)

# === Strict & Safe Mode ===
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "Continue"
$InformationPreference = "Continue"

# === Импорт утилит ===
$libsRoot = Join-Path $PSScriptRoot "..\..\Libs\PS" -Resolve

Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force
Import-Module (Join-Path $libsRoot "AccessUtils.psm1") -Force

Confirm-RunAsAdmin

# === Config ===
$binariesDir = Join-Path $PSScriptRoot "..\..\Binaries" -Resolve
$saltBinariesDir = Join-Path $binariesDir "Salt" -Resolve

$hostname = $env:COMPUTERNAME

$saltMinionPath = "$SaltInstallDir\ssm.exe"
$saltMinionInstallerPath = Join-Path $saltBinariesDir "salt-minion-installer.exe" 

# === Logs ===
$timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")

$logDir = Join-Path $PSScriptRoot "logs"
$logFile = Join-Path $logDir "$timestamp-$hostname.log"
$global:logFile = $logFile

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

# === Startup ===
Write-LogMessage "=== Установка Salt Minion ($hostname) ==="
Write-LogMessage "Master: $MasterAddress"
Write-LogMessage "Minion ID: $MinionId"

# === Проверяем наличие C:\Tools ===
if (-not (Test-Path $BaseToolsDir)) {
    Write-LogMessage "Создаю директорию $BaseToolsDir"
    New-Item -ItemType Directory -Path $BaseToolsDir -Force | Out-Null
}

# === Проверяем существующую установку ===
if (-not $SkipInstallCheck -and (Test-Path "$saltMinionPath")) {
    Write-LogMessage "Salt Minion уже установлен в $SaltInstallDir — пропускаю установку." "WARN"
    exit 0
}

# === Тихая установка ===
Write-LogMessage "Запускаю установку Salt Minion"
$installArgs = "/S /master=$MasterAddress /minion-name=$MinionId /install-dir=$SaltInstallDir"
Start-Process -FilePath $saltMinionInstallerPath -ArgumentList $installArgs -Wait -PassThru | Out-Null

Write-LogMessage "Директория Salt minion: $SaltInstallDir"

$status = (Get-Service salt-minion).Status
Write-LogMessage "Статус службы: $status"

if ($status -ne "Running") {
    Write-LogMessage "Salt Minion не запущен. Проверь логи вручную." "ERROR"
    exit 1
}

Write-LogMessage "=== Установка Salt Minion завершена успешно ==="
