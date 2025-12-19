<#
.SYNOPSIS
  Загрузка переменных окружения из файла
  ТОЛЬКО для текущего процесса PowerShell.
#>

[CmdletBinding()]
param(
    [string]$VarsFile
)

# === Strict & Safe Mode ===
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"


# === Импорт логирования ===
$libsRoot = Join-Path $PSScriptRoot "..\..\Libs\PS" -Resolve
Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force
Import-Module (Join-Path $libsRoot "DefaultConfig.psm1") -Force

$cfg = Get-Defaults 

if (-not $PSBoundParameters.ContainsKey('VarsFile')) {
    $VarsFile = $cfg.EnvironmentPath 
}

# === Контекст ===
$hostname = $env:COMPUTERNAME
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

$logDir = Join-Path (Join-Path $PSScriptRoot "logs") $hostname
$logFile = Join-Path $logDir "$timestamp.log"
$global:logFile = $logFile

New-Item -ItemType Directory -Path $logDir -Force | Out-Null

Write-LogMessage "=== Загрузка process-level переменных окружения ==="
Write-LogMessage "Файл: $VarsFile"

if (-not (Test-Path $VarsFile)) {
    Write-LogMessage "Файл не найден: $VarsFile" "ERROR"
    throw "Vars file not found"
}

$lines = Get-Content -Path $VarsFile -ErrorAction Stop

$loaded = 0
$skipped = 0

foreach ($line in $lines) {
    $line = $line.Trim()

    if (-not $line -or $line.StartsWith('#') -or $line.StartsWith(';')) {
        continue
    }

    if ($line -notmatch '^\s*([^=]+?)\s*=\s*(.*)\s*$') {
        Write-LogMessage "Некорректная строка (пропущена): $line" "WARN"
        $skipped += 1
        continue
    }

    $name = $matches[1].Trim()
    $value = $matches[2]

    $current = [Environment]::GetEnvironmentVariable($name, 'Process')

    if ($current -eq $value) {
        Write-LogMessage "Переменная $name уже задана — пропуск"
        $skipped += 1
        continue
    }

    [Environment]::SetEnvironmentVariable($name, $value, 'Process')
    Write-LogMessage "Установлена переменная $name"
    
    $loaded += 1
}

Write-LogMessage "Загружено: $loaded"
Write-LogMessage "Пропущено: $skipped"
Write-LogMessage "=== Готово ==="
