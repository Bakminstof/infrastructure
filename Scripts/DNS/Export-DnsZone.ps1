<#
.SYNOPSIS
  Экспорт статических A-записей DNS-зоны в файл формата hosts
  с фильтрацией по IP-префиксу.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$ZoneName,

    [Parameter(Mandatory)]
    [string]$IpPrefix, # пример: 10.23.100.

    [string]$OutputFile
)

# === Strict & Safe Mode ===
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# === Импорт логирования ===
$libsRoot = Join-Path $PSScriptRoot "..\..\Libs\PS" -Resolve
Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force

# === Проверка модуля DNS ===
if (-not (Get-Module -ListAvailable -Name DnsServer)) {
    Write-LogMessage "Модуль DnsServer не найден. Скрипт должен выполняться на DNS-сервере." "ERROR"
    exit 1
}

Import-Module DnsServer -Force

# === Контекст ===
$hostname = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$logDir = Join-Path (Join-Path $PSScriptRoot "logs") $hostname
$logFile = Join-Path $logDir "$timestamp.log"
$global:logFile = $logFile

$zonesDir = Join-Path $PSScriptRoot "Zones"

if (-not $PSBoundParameters.ContainsKey('OutputFile')) {
    $OutputFile = Join-Path $zonesDir "hosts"
}

Write-LogMessage "=== Экспорт зоны $ZoneName ==="
Write-LogMessage "IP фильтр: $IpPrefix*"
Write-LogMessage "Файл вывода: $OutputFile"

# === Получение A-записей ===
try {
    Write-LogMessage "Получаю A-записи зоны..."
    $records = Get-DnsServerResourceRecord -ZoneName $ZoneName -RRType A
}
catch {
    Write-LogMessage "Ошибка получения записей зоны: $_" "ERROR"
    exit 1
}

# === Фильтрация статических записей + IP префикс ===
$filtered = $records |
Where-Object {
    $_.RecordData.IPv4Address -ne $null -and
    $_.RecordData.IPv4Address.IPAddressToString.StartsWith($IpPrefix)
}

Write-LogMessage "Подходящих записей: $($filtered.Count)"

# === Формирование hosts ===
$hostsLines = $filtered | Sort-Object HostName | ForEach-Object {
    $ip = $_.RecordData.IPv4Address.IPAddressToString

    $name = if ($_.HostName -eq '@') {
        $ZoneName
    }
    else {
        "$($_.HostName).$ZoneName"
    }

    "{0,-15} {1}" -f $ip, $name
}

# === Запись файла ===
try {
    @(
        "# Exported from DNS zone: $ZoneName"
        "# Date: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"
        "# Filter: $IpPrefix*"
        ""
    ) + $hostsLines | Set-Content -Path $OutputFile -Encoding ASCII

    Write-LogMessage "Экспорт успешно завершён"
}
catch {
    Write-LogMessage "Ошибка записи файла: $_" "ERROR"
    exit 1
}

Write-LogMessage "=== Готово ==="
