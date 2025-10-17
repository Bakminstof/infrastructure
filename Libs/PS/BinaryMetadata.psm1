<#
.SYNOPSIS
  Работа с метаданными бинарников.
.DESCRIPTION
  Модуль предоставляет функции для создания, чтения и обновления метаданных бинарного файла.
#>

# === Настройка кодировки для вывода в файл ===
$PSDefaultParameterValues['Out-File:Encoding'] = 'utf8BOM'

if ($PSVersionTable.PSVersion.Major -lt 6) {
    $OutFileEncoding = [System.Text.Encoding]::UTF8
} else {
    $OutFileEncoding = 'utf8'
}

function Get-BinaryMetadata {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        return $null
    }

    try {
        $json = Get-Content -Path $FilePath -Raw
        return ConvertFrom-Json $json
    } catch {
        Write-Warning "Не удалось прочитать метаданные: $_"
        return @{}
    }
}

function Update-BinaryMetadata {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath,
        [Parameter(Mandatory)]
        [string]$Name,
        [Parameter(Mandatory)]
        [string]$Version
    )

    $utcNow = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $metadata = Get-BinaryMetadata -FilePath $FilePath

    if ($metadata) {
        $metadata.Version = $Version
        $metadata.UpdatedAt = $utcNow
    } else {
        $metadata = [PSCustomObject]@{
            Name      = $Name
            Version   = $Version
            CreatedAt = $utcNow
            UpdatedAt = $utcNow
        }
    }

    $json = $metadata | ConvertTo-Json -Depth 10 -Compress:$false

    $utf8BOM = New-Object System.Text.UTF8Encoding $true
    [System.IO.File]::WriteAllText($FilePath, $json, $utf8BOM)
}

function Get-BinaryVersion {
    param (
        [Parameter(Mandatory)]
        [string]$FilePath
    )

    $metadata = Get-BinaryMetadata -FilePath $FilePath
    if ($metadata) {
        return $metadata.Version
    }
    return $null
}
