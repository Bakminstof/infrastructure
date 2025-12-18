<#
.SYNOPSIS
  Проверка и (опционально) настройка NTP-клиента Windows.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$NtpServer,

    [switch]$Configure,

    [int]$Samples = 3,

    [int]$MaxOffsetMs = 5000
)

# === Strict & Safe Mode ===
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "Continue"
$InformationPreference = "Continue"

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

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Write-LogMessage "=== Проверка NTP-клиента ($hostname) ==="
Write-LogMessage "Целевой NTP-сервер: $NtpServer"
Write-LogMessage "Режим автонастройки: $Configure"

# === Настройка службы времени (если указано) ===
if ($Configure) {
    Write-LogMessage "Проверка службы Windows Time (w32time)"

    $service = Get-Service w32time -ErrorAction SilentlyContinue

    if (-not $service) {
        Write-LogMessage "Служба w32time не найдена. Установка невозможна" "ERROR"
        exit 1
    }

    # Устанавливаем автоматический старт
    Set-Service w32time -StartupType Automatic
    Write-LogMessage "Служба w32time настроена на автоматический запуск"

    # Перезапуск службы
    if ($service.Status -ne 'Running') {
        Write-LogMessage "Запуск службы w32time"
        Start-Service w32time
    }
    else {
        Write-LogMessage "Перезапуск службы w32time"
        Restart-Service w32time -Force
    }
}

# === Текущий источник ===
$currentSource = w32tm /query /source
Write-LogMessage "Текущий источник времени: $currentSource"

$needsConfig = $false

if ($currentSource -match "Local CMOS Clock") {
    Write-LogMessage "Клиент не использует NTP" "WARN"
    $needsConfig = $true
}

if ($currentSource -notmatch [regex]::Escape($NtpServer)) {
    Write-LogMessage "Текущий сервер не совпадает с целевым" "WARN"
    $needsConfig = $true
}

# === Автонастройка клиента ===
if ($Configure -and $needsConfig) {
    Write-LogMessage "Настраиваю NTP-клиент на сервер $NtpServer"

    w32tm /config `
        /manualpeerlist:$NtpServer `
        /syncfromflags:manual `
        /reliable:no `
        /update | Out-Null

    # Перезапуск службы после конфигурации
    Restart-Service w32time -Force
    Start-Sleep -Seconds 3

    $currentSource = w32tm /query /source
    Write-LogMessage "Новый источник времени: $currentSource"
}

elseif ($needsConfig) {
    Write-LogMessage "Требуется настройка NTP-клиента (запусти с -Configure)" "ERROR"
    exit 1
}

# === Stripchart ===
Write-LogMessage "Проверка ответа сервера (stripchart)"

$stripchart = w32tm /stripchart `
    /computer:$NtpServer `
    /dataonly `
    /samples:$Samples 2>&1

Write-LogMessage ($stripchart -join "`n")

# === Анализ смещения ===
$offsets = @()

foreach ($line in $stripchart) {
    if ($line -match '([-+]?\d+\.\d+)s') {
        $offsets += [math]::Abs([double]$Matches[1] * 1000)
    }
}

if (-not $offsets) {
    Write-LogMessage "Не удалось получить смещение времени" "ERROR"
    exit 1
}

$maxOffset = ($offsets | Measure-Object -Maximum).Maximum
Write-LogMessage "Максимальное смещение: ${maxOffset} ms"

if ($maxOffset -gt $MaxOffsetMs) {
    Write-LogMessage "Смещение превышает допустимое (${MaxOffsetMs} ms)" "ERROR"
    exit 1
}

# === Финальная синхронизация ===
Write-LogMessage "Принудительная синхронизация"
w32tm /resync /force | Out-Null

Write-LogMessage "=== NTP-клиент настроен и работает корректно ==="
Write-LogMessage "Лог: $logFile"
