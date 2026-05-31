function Get-UInt32FromBlob {
    params (
        $blob,
        $offset
    )

    [System.BitConverter]::ToUInt32($blob, $offset)
}

<#
    .DESCRIPTION
    Converts an object read from REG_BINARY registry values to a hex string
#>
function Convert-BlobToHexString {}

<#
    .DESCRIPTION
    Converts a hex string to an object ready to be put to the Windows registry as a REG_BINARY value
#>
function Convert-HexStringToBlob {}

<#
    .DESCRIPTION
    Converts a hex string to a PS object
#>
function Convert-HexStringToObject {}

<#
    .DESCRIPTION
    Converts an object read from REG_BINARY registry values to a PS object
#>
function Convert-BlobToObject {
    [CmdletBinding()]
    param (
        $BinaryData
    )

    if ([System.BitConverter]::ToUInt32($BinaryData, 0) -ne 70) {
        Write-Debug "Input data should start with 70 (0x46)"
        break
    }
    $BlobVersion = [System.BitConverter]::ToUInt32($BinaryData, 4)
    Write-Debug "`$BlobVersion = $BlobVersion"
    $OptionFlags = [System.BitConverter]::ToUInt32($BinaryData, 8)
    Write-Debug "`$OptionFlags = $OptionFlags"
    $Offset = 12
    Write-Debug "`$Offset = $Offset"

    if (-not $OptionFlags -band 1) {
        return $false # TODO: To be reconsidered
    }
    $ProxyLength = [System.BitConverter]::ToUInt32($BinaryData, $Offset)
    Write-Debug "`$ProxyLength = $ProxyLength"
    $Offset += 4
    Write-Debug "`$Offset = $Offset"
    if ($ProxyLength) {
        $Proxy = [System.Text.Encoding]::UTF8.GetString($BinaryData, $Offset, ($ProxyLength + 1))
        Write-Debug "`$Proxy = $Proxy"
        $Offset += $ProxyLength
        Write-Debug "`$Offset = $Offset"
    }

    $ProxyBypassLength = [System.BitConverter]::ToUInt32($BinaryData, $Offset)
    Write-Debug "`$ProxyBypassLength = $ProxyBypassLength"
    $Offset += 4
    Write-Debug "`$Offset = $Offset"
    if ($ProxyBypassLength) {
        $ProxyBypass = [System.Text.Encoding]::UTF8.GetString($BinaryData, $Offset, ($ProxyBypassLength + 1))
        Write-Debug "`$ProxyBypass = $ProxyBypass"
        $Offset += $ProxyBypassLength
        Write-Debug "`$Offset = $Offset"
    }

    $AutoConfigUrlLength = [System.BitConverter]::ToUInt32($BinaryData, $Offset)
    Write-Debug "`$AutoConfigUrlLength = $AutoConfigUrlLength"
    $Offset += 4
    Write-Debug "`$Offset = $Offset"
    if ($AutoConfigUrlLength) {
        $AutoConfigUrl = [System.Text.Encoding]::UTF8.GetString($BinaryData, $Offset, ($AutoConfigUrlLength + 1))
        Write-Debug "`$AutoConfigUrl = $AutoConfigUrl"
        $Offset += $AutoConfigUrlLength
        Write-Debug "`$Offset = $Offset"
    }

    [PSCustomObject]@{
        AutoDetect = [bool]($OptionFlags -band 8)
        AutoConfigUrlEnabled = [bool]($OptionFlags -band 4)
        AutoConfigUrl = $AutoConfigUrl
        ProxyEnabled = [bool]($OptionFlags -band 2)
        Proxy = $Proxy
        ProxyBypass = $ProxyBypass
        BlobVersion = $BlobVersion
    }
}

<#
    .DESCRIPTION
    Converts a PS object to hex string
#>
function Convert-ObjectToHexString {}

<#
    .DESCRIPTION
    Converts a PS object to an object ready to be put to the Windows registry as a REG_BINARY value
#>
function Convert-ObjectToBlob {}

<#
    .DESCRIPTION
    Reads the content of text proxy settings from Windows registry
#>
function Get-TextConfig {
    [PSCustomObject]@{
        AutoConfigUrl = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl
        ProxyEnable = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable
        ProxyServer = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer
        ProxyOverride = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride
        ProxySettingsPerUser = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxySettingsPerUser
    }
}

<#
    .DESCRIPTION
    Reads the content of binary proxy settings from Windows registry
#>
function Get-BinaryConfig {
    [PSCustomObject]@{
        DefaultConnectionSettings = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name DefaultConnectionSettings
        SavedLegacySettings = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name SavedLegacySettings
    }
}

<#
    .DESCRIPTION
    Write new proxy config to the registry
#>
function Write-Config {
    param (
        $AutoDetect = 0,
        $AutoConfigUrl,
        $ProxyEnable = 0,
        $ProxyServer,
        $ProxyOverride#,
        # $DefaultConnectionSettings,
        # $SavedLegacySettings
    )
    
    # if ($AutoDetect -eq $false) {
    #     Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoDetect
    #     Remove-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoDetect
    # }

    # if ($AutoConfigUrl -eq $false) {
    #     Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl
    #     Remove-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl
    # }

    # if ($ProxyEnable -eq $false) {
    #     Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable
    #     Remove-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable
    # }
    
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoDetect -Value $AutoDetect
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl -Value $AutoConfigUrl
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value $ProxyEnable
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value $ProxyServer
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value $ProxyOverride
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoDetect -Value $AutoDetect
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl -Value $AutoConfigUrl
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value $ProxyEnable
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value $ProxyServer
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value $ProxyOverride
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name DefaultConnectionSettings -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name SavedLegacySettings -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name DefaultConnectionSettings -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name SavedLegacySettings -ErrorAction SilentlyContinue
}
