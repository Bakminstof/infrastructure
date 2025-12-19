<#
.SYNOPSIS
  Bootstrap для обновления hosts и установки Salt Minion.
.DESCRIPTION
  Загружает переменные окружения, обновляет hosts и устанавливает Salt Minion.
#>
[CmdletBinding()]
param(
  [Parameter(Mandatory)]
  [string]$MinionID
)
# === Strict & Safe Mode ===
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "Continue"
$InformationPreference = "Continue"

# === Импорт утилит ===
$libsRoot = Join-Path $PSScriptRoot "..\Libs\PS" -Resolve

Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force
Import-Module (Join-Path $libsRoot "DefaultConfig.psm1") -Force
Import-Module (Join-Path $libsRoot "AccessUtils.psm1") -Force

Confirm-RunAsAdmin

# === Получение конфигурации ===
$cfg = Get-Defaults
$scriptsRoot = Join-Path $cfg.RootDir "Scripts" -Resolve

# === Подгружаем переменные окружения ===
$loadEnvScript = Join-Path $scriptsRoot "ENV\Load-EnvVars.ps1"
. $loadEnvScript

Write-LogMessage "=== Environment variables loaded ===" -NoFileLog
Write-LogMessage "BASE_TOOLS_DIR = $env:IF_WINDOWS_BASE_TOOLS_DIR" -NoFileLog
Write-LogMessage "HOSTS_SOURCE   = $env:IF_HOSTS_SOURCE" -NoFileLog
Write-LogMessage "SALT_MASTER    = $env:IF_SALT_MASTER" -NoFileLog

# === Пути к скриптам ===
$updateHostsScript = Join-Path $scriptsRoot "DNS\Update-HostsFromSource.ps1"
$installSaltScript = Join-Path $scriptsRoot "Salt\Install-SaltMinion.ps1"

# === Обновление hosts ===
Write-LogMessage "=== Updating hosts file ===" -NoFileLog

& $updateHostsScript -SourceHostsPath $env:IF_HOSTS_SOURCE
if ($LASTEXITCODE -ne 0) {
  Write-LogMessage "[ERROR] Hosts update failed" -NoFileLog
  exit 1
}

# === Установка Salt Minion ===
Write-LogMessage "=== Installing Salt Minion ===" -NoFileLog

$skipInstallCheckSwitch = if ($env:SKIP_INSTALL_CHECK -eq "1") { "-SkipInstallCheck" } else { "" }

& $installSaltScript `
  -MasterAddress $env:SALT_MASTER `
  -MinionId $MinionID `
  -BaseToolsDir $env:BASE_TOOLS_DIR `
  $skipInstallCheckSwitch

if ($LASTEXITCODE -ne 0) {
  Write-LogMessage "[ERROR] Salt Minion installation failed" -NoFileLog
  exit 1
}

Write-LogMessage "=== Bootstrap completed successfully ===" -NoFileLog
