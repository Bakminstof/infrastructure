# LoggingUtils.psm1
# Универсальное логирование в UTF-8 с BOM

[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'

function Write-LogMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR", "DEBUG")] [string]$Level = "INFO",
        [switch]$NoConsole
    )

    if (-not (Get-Variable -Name logFile -Scope Global -ErrorAction SilentlyContinue)) {
        $global:logFile = Join-Path $PSScriptRoot "default.log"
    }

    $time = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "[$time][$Level] $Message"

    $utf8BOM = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::AppendAllText($logFile, "$line`r`n", $utf8BOM)

    if (-not $NoConsole) {
        switch ($Level) {
            "INFO" { Write-Host $line -ForegroundColor White }
            "WARN" { Write-Host $line -ForegroundColor Yellow }
            "ERROR" { Write-Host $line -ForegroundColor Red }
            "DEBUG" { Write-Host $line -ForegroundColor DarkGray }
        }
    }
}
