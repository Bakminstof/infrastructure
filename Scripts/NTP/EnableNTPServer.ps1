<#
.SYNOPSIS
  Включение и настройка NTP-сервера (w32time) на Windows.
#>

[CmdletBinding()]
param(
    [switch]$SkipFirewall
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

# === Контекст выполнения ===
$hostname = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$logDir = Join-Path (Join-Path $PSScriptRoot "logs") $hostname
$logFile = Join-Path $logDir "$timestamp.log"
$global:logFile = $logFile

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Write-LogMessage "=== Включение NTP-сервера ($hostname) ==="

# === Настройка реестра ===
$ntpServerKey = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\TimeProviders\NtpServer"
$configKey = "HKLM:\SYSTEM\CurrentControlSet\Services\W32Time\Config"

Write-LogMessage "Включаю NTP Server provider"
Set-ItemProperty -Path $ntpServerKey -Name Enabled -Type DWord -Value 1

Write-LogMessage "Устанавливаю AnnounceFlags = 5 (Reliable Time Source)"
Set-ItemProperty -Path $configKey -Name AnnounceFlags -Type DWord -Value 5

# === Обновление конфигурации службы ===
Write-LogMessage "Применяю конфигурацию w32time"
w32tm /config /update | Out-Null

# === Перезапуск службы ===
Write-LogMessage "Перезапускаю службу Windows Time (w32time)"
Restart-Service w32time -Force

$service = Get-Service w32time
Write-LogMessage "Статус службы w32time: $($service.Status)"

if ($service.Status -ne 'Running') {
    Write-LogMessage "Служба w32time не запущена" "ERROR"
    exit 1
}

# === Брандмауэр ===
if (-not $SkipFirewall) {
    Write-LogMessage "Проверяю правило брандмауэра для UDP 123"

    $rule = Get-NetFirewallRule -DisplayName "NTP Server (UDP 123)" -ErrorAction SilentlyContinue
    if (-not $rule) {
        Write-LogMessage "Добавляю правило брандмауэра UDP 123"
        New-NetFirewallRule `
            -Name "NTP-Server-UDP-123" `
            -DisplayName "NTP Server (UDP 123)" `
            -Protocol UDP `
            -LocalPort 123 `
            -Direction Inbound `
            -Action Allow | Out-Null
    }
    else {
        Write-LogMessage "Правило брандмауэра уже существует"
    }
}

# === Проверка ===
Write-LogMessage "Проверка конфигурации NTP"
$cfg = w32tm /query /configuration
Write-LogMessage ($cfg -join "`n")

Write-LogMessage "=== NTP-сервер успешно включён. Лог: $logFile ==="
