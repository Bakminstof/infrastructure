<#
.SYNOPSIS
  Замена локального файла hosts файлом, полученным по указанному пути.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$SourceHostsPath
)

# === Strict & Safe Mode ===
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# === Импорт библиотек ===
$libsRoot = Join-Path $PSScriptRoot "..\..\Libs\PS" -Resolve
Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force
Import-Module (Join-Path $libsRoot "AccessUtils.psm1") -Force

Confirm-RunAsAdmin

# === Контекст ===
$hostname = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$logDir = Join-Path (Join-Path $PSScriptRoot "logs") $hostname
$logFile = Join-Path $logDir "$timestamp.log"
$global:logFile = $logFile

$backupDir = Join-Path (Join-Path $PSScriptRoot "backups") $hostname
New-Item -ItemType Directory -Path $logDir -Force | Out-Null
New-Item -ItemType Directory -Path $backupDir -Force | Out-Null

$localHosts = "$env:SystemRoot\System32\drivers\etc\hosts"
$backupFile = Join-Path $backupDir "hosts.$timestamp.bak"

Write-LogMessage "=== Обновление hosts на $hostname ==="
Write-LogMessage "Источник: $SourceHostsPath"
Write-LogMessage "Локальный hosts: $localHosts"

# === Проверки ===
if (-not (Test-Path $SourceHostsPath)) {
    Write-LogMessage "Файл-источник не найден: $SourceHostsPath" "ERROR"
    exit 1
}

# === Проверка доступности источника ===
try {
    Get-Content $SourceHostsPath -ErrorAction Stop | Out-Null
}
catch {
    Write-LogMessage "Нет доступа к файлу-источнику: $_" "ERROR"
    exit 1
}

# === Backup текущего hosts ===
try {
    Copy-Item -Path $localHosts -Destination $backupFile -Force
    Write-LogMessage "Backup создан: $backupFile"
}
catch {
    Write-LogMessage "Ошибка создания backup hosts: $_" "ERROR"
    exit 1
}

# === Замена hosts ===
try {
    Copy-Item -Path $SourceHostsPath -Destination $localHosts -Force
    Write-LogMessage "hosts успешно обновлён"
}
catch {
    Write-LogMessage "Ошибка обновления hosts: $_" "ERROR"
    exit 1
}

Write-LogMessage "=== Готово ==="
