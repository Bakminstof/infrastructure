# LoggingUtils.psm1
# Универсальное логирование (PowerShell 2.0+ / PS Core)
# Поддержка отключения вывода в файл (-NoFileLog) и консоль (-NoConsole)
# Поддержка цветного вывода в интерактивной консоли

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")]
        [string]$Level = "INFO",

        [switch]$NoConsole,
        [switch]$NoFileLog
    )

    # === Определяем лог-файл ===
    if (-not (Get-Variable -Name logFile -Scope Global -ErrorAction SilentlyContinue)) {
        $global:logFile = Join-Path $PSScriptRoot "default.log"
    }

    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$time][$Level] $Message"

    # === Запись в файл ===
    if (-not $NoFileLog) {
        try {
            $logDir = Split-Path $logFile -Parent
            if (-not (Test-Path $logDir)) {
                New-Item -ItemType Directory -Path $logDir -Force | Out-Null
            }

            $utf8BOM = New-Object System.Text.UTF8Encoding($true)
            [System.IO.File]::AppendAllText($logFile, "$line`r`n", $utf8BOM)
        }
        catch {
            # fallback: вывод предупреждения в консоль
            Write-Output ("[WARN] Ошибка записи в лог-файл '{0}': {1}" -f $logFile, $_.Exception.Message)
        }
    }

    # === Вывод в консоль (если не отключено) ===
    if (-not $NoConsole) {
        $color = "White"
        switch ($Level) {
            "INFO" { $color = "White" }
            "WARN" { $color = "Yellow" }
            "ERROR" { $color = "Red" }
            "DEBUG" { $color = "Gray" }
        }

        if ($Host.UI -and $Host.UI.RawUI) {
            try { Write-Host $line -ForegroundColor $color } catch { Write-Output $line }
        }
        else {
            Write-Output $line
        }
    }
}
