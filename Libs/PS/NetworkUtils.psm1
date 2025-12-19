# NetworkUtils.psm1
# Универсальные сетевые утилиты

function Invoke-DhcpRelease {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$AdapterName)
    
    Write-LogMessage "ipconfig /release $AdapterName"
    Start-Process -FilePath ipconfig -ArgumentList "/release `"$AdapterName`"" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}

function Invoke-DhcpRenew {
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$AdapterName)

    Write-LogMessage "ipconfig /renew $AdapterName"
    Start-Process -FilePath ipconfig -ArgumentList "/renew `"$AdapterName`"" -NoNewWindow -Wait -ErrorAction SilentlyContinue
}

function Wait-NetworkAdapterState {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][int]$InterfaceIndex,
        [ValidateSet('Up', 'Down', 'Disabled')] [string]$DesiredState,
        [int]$TimeoutSec = 30
    )

    $deadline = (Get-Date).AddSeconds($TimeoutSec)
    while ((Get-Date) -lt $deadline) {
        $status = (Get-NetAdapter -InterfaceIndex $InterfaceIndex -ErrorAction SilentlyContinue).Status
        if (-not $status) { Start-Sleep -Milliseconds 300; continue }
        switch ($DesiredState) {
            'Up' { if ($status -eq 'Up') { return $true } }
            'Down' { if ($status -in 'Down', 'Disconnected') { return $true } }
            'Disabled' { if ($status -eq 'Disabled') { return $true } }
        }
        Start-Sleep -Milliseconds 500
    }
    Write-LogMessage "Адаптер $InterfaceIndex не достиг состояния '$DesiredState' за $TimeoutSec сек" "WARN"
    return $false
}

function Save-NetworkConfig {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$BackupFile,
        [Parameter(Mandatory)][array]$Adapters
    )

    $backupData = @{}
    foreach ($if in $Adapters) {
        $entry = [ordered]@{
            Name           = $if.Name
            InterfaceIndex = $if.InterfaceIndex
            Description    = $if.InterfaceDescription
            Status         = $if.Status
            IPv4           = @()
            IPv6           = @()
            DNS            = (Get-DnsClientServerAddress -InterfaceIndex $if.InterfaceIndex -ErrorAction SilentlyContinue |
                Select-Object -ExpandProperty ServerAddresses)
            DHCPv4         = (Get-NetIPInterface -InterfaceIndex $if.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue).Dhcp
            DHCPv6         = (Get-NetIPInterface -InterfaceIndex $if.InterfaceIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue).Dhcp
        }

        $ipv4 = Get-NetIPAddress -InterfaceIndex $if.InterfaceIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
        foreach ($ip in $ipv4) {
            $entry.IPv4 += [ordered]@{
                Address      = $ip.IPAddress
                PrefixLength = $ip.PrefixLength
                Origin       = $ip.PrefixOrigin
            }
        }

        $ipv6 = Get-NetIPAddress -InterfaceIndex $if.InterfaceIndex -AddressFamily IPv6 -ErrorAction SilentlyContinue
        foreach ($ip in $ipv6) {
            $entry.IPv6 += [ordered]@{
                Address      = $ip.IPAddress
                PrefixLength = $ip.PrefixLength
                Origin       = $ip.PrefixOrigin
            }
        }

        $backupData[$if.Name] = $entry
    }

    try {
        $json = $backupData | ConvertTo-Json -Depth 10 -Compress:$false
        $utf8BOM = New-Object System.Text.UTF8Encoding $true
        [System.IO.File]::WriteAllText($BackupFile, $json, $utf8BOM)
        Write-LogMessage "Бэкап сохранён: $BackupFile"
    }
    catch {
        Write-LogMessage "Ошибка при сохранении бэкапа: $_" "ERROR"
    }
}

function Set-AdapterDhcp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$AdapterName
    )

    # Получаем индекс адаптера
    $adapter = Get-NetAdapter -Name $AdapterName -ErrorAction SilentlyContinue
    if (-not $adapter) {
        Write-LogMessage "Адаптер $AdapterName не найден" "ERROR"
        return
    }
    $idx = $adapter.InterfaceIndex

    try {
        Write-LogMessage "Включаю DHCP для IP на адаптере $AdapterName"
        Set-NetIPInterface -InterfaceIndex $idx -Dhcp Enabled -ErrorAction Stop

        Write-LogMessage "Сбрасываю DNS для адаптера $AdapterName"
        Set-DnsClientServerAddress -InterfaceIndex $idx -ResetServerAddresses -ErrorAction Stop

        # Очистка кеша DNS
        Clear-DnsClientCache | Out-Null

        # Освобождаем и заново получаем IP
        Invoke-DhcpRelease $AdapterName
        Invoke-DhcpRenew $AdapterName

        Write-LogMessage "Адаптер $AdapterName успешно переключен на DHCP"
    }
    catch {
        Write-LogMessage "Ошибка при переводе адаптера $AdapterName на DHCP: $_" "ERROR"
    }
}
