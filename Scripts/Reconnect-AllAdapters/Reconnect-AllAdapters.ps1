<#
.SYNOPSIS
  Сброс IP/DNS и переподключение всех физических сетевых адаптеров.
#>

[CmdletBinding()]
param(
    [switch]$SkipBackup
)

# === Импорт библиотек ===
$libsRoot = Join-Path $PSScriptRoot "..\..\Libs\PS"
Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force
Import-Module (Join-Path $libsRoot "NetworkUtils.psm1") -Force
Import-Module (Join-Path $libsRoot "AccessUtils.psm1") -Force

Confirm-RunAsAdmin

$hostname = $env:COMPUTERNAME
$timestamp = (Get-Date -Format "yyyyMMdd_HHmmss")
$backupDir = Join-Path (Join-Path $PSScriptRoot "backups") $hostname
$logDir = Join-Path (Join-Path $PSScriptRoot "logs") $hostname
$backupFile = Join-Path $backupDir "$timestamp.json"
$logFile = Join-Path $logDir "$timestamp.log"
$global:logFile = $logFile

New-Item -ItemType Directory -Path $backupDir -Force | Out-Null
New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Write-LogMessage "=== Запуск обработки ($hostname) ==="

$excludePattern = '(Virtual|Hyper-V|Loopback|TAP|Bluetooth|Miniport|Hamachi|ZeroTier|VMware|Firezone|Wireguard)'
$adapters = Get-NetAdapter |
Where-Object { $_.Status -notin @('Not Present', 'Unknown') -and $_.InterfaceDescription -notmatch $excludePattern } |
Sort-Object InterfaceIndex

if (-not $adapters) {
    Write-LogMessage "Не найдено сетевых адаптеров" "ERROR"
    exit 1
}

if (-not $SkipBackup) {
    Save-NetworkConfig -BackupFile $backupFile -Adapters $adapters
}

foreach ($if in $adapters) {
    $name = $if.Name
    $idx = $if.InterfaceIndex

    Write-LogMessage "=== Обработка адаптера: $name ==="

    try {
        Write-LogMessage "Сброс DNS"
        Set-DnsClientServerAddress -InterfaceIndex $idx -ResetServerAddresses -ErrorAction Stop
        Clear-DnsClientCache | Out-Null
    } catch { Write-LogMessage "Ошибка сброса DNS: $_" "WARN" }

    $ipIfV4 = Get-NetIPInterface -InterfaceIndex $idx -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($ipIfV4.Dhcp -eq 'Enabled') {
        Invoke-DhcpRelease $name
    } else {
        Get-NetIPAddress -InterfaceIndex $idx -AddressFamily IPv4 -ErrorAction SilentlyContinue |
        Where-Object { $_.PrefixOrigin -eq 'Manual' } |
        ForEach-Object {
            Write-LogMessage "Удаляю IPv4 $($_.IPAddress)"
            Remove-NetIPAddress -InterfaceIndex $idx -IPAddress $_.IPAddress -Confirm:$false -ErrorAction SilentlyContinue
        }
    }

    # Отключение / включение
    Write-LogMessage "Отключаю адаптер $name"
    Disable-NetAdapter -Name $name -Confirm:$false -ErrorAction SilentlyContinue
    Wait-NetworkAdapterState -InterfaceIndex $idx -DesiredState 'Disabled' | Out-Null
    Start-Sleep -Seconds 3

    Write-LogMessage "Включаю адаптер $name"
    Enable-NetAdapter -Name $name -Confirm:$false -ErrorAction SilentlyContinue
    Wait-NetworkAdapterState -InterfaceIndex $idx -DesiredState 'Up' | Out-Null
    Start-Sleep -Seconds 5

    Invoke-DhcpRenew $name
    Write-LogMessage "Завершена обработка $name"
}

Write-LogMessage "=== Завершено. Лог: $logFile ==="
