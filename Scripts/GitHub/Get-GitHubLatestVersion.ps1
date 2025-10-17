<#
.SYNOPSIS
  Получение последней версии проекта с GitHub.
.DESCRIPTION
  Скрипт обращается к GitHub API и возвращает последнюю опубликованную версию (tag_name).
.EXAMPLE
  .\Get-GitHubLatestVersion.ps1 -Repo "saltstack/salt"
  Вернёт, например: v3007.0
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Repo,  # Пример: "saltstack/salt"

    [string]$GitHubApiUrl = "https://api.github.com/repos",

    [switch]$Quiet  # если указан — выводит только номер версии
)

# === Strict & Safe Mode ===
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
$WarningPreference = "Continue"
$InformationPreference = "Continue"

# === Подключение библиотек ===
$libsRoot = Join-Path $PSScriptRoot "..\..\Libs\PS" -Resolve

Import-Module (Join-Path $libsRoot "LoggingUtils.psm1") -Force

# === Trap для ошибок через логирование ===
trap {
    Write-LogMessage "❌ Ошибка: $($_.Exception.Message)" "ERROR" -NoFileLog
    exit 1
}

# === Формируем URL ===
$url = "$GitHubApiUrl/$Repo/releases/latest"
Write-LogMessage "📡 Получаю последнюю версию из $url"  -NoFileLog

try {
    $headers = @{ "Accept" = "application/vnd.github.v3+json" }
    $response = Invoke-RestMethod -Uri $url -Headers $headers -UseBasicParsing
} catch {
    Write-LogMessage "Не удалось получить данные из GitHub API. Проверь имя репозитория или соединение." "ERROR" -NoFileLog
    exit 1
}

if (-not $response.tag_name) {
    Write-LogMessage "API не вернул тег версии. Возможно, в проекте нет релизов." "ERROR" -NoFileLog
    exit 1
}

$latestVersion = $response.tag_name

if ($Quiet) {
    Write-Output $latestVersion
} else {
    Write-LogMessage "✅ Последняя версия проекта '$Repo': $latestVersion" -NoFileLog
}

exit 0
