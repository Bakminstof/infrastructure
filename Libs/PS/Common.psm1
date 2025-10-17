<#
.SYNOPSIS
  Различные функции.
.DESCRIPTION
  Модуль содержит различные функции.
#>

function Test-AppInstalled {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$AppName
    )

    $uninstallPaths = @(
        "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
        "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
    )

    foreach ($path in $uninstallPaths) {
        Get-ItemProperty $path -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.PSObject.Properties.Name -contains 'DisplayName' -and $_.DisplayName -like "*$AppName*") {
                return $_
            }
        }
    }
    return $null
}
