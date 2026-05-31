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
function Convert-BlobToObject {}

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
        AutoConfigUrl = Get-ItemPropertyValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl
        ProxyEnable = Get-ItemPropertyValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable
        ProxyServer = Get-ItemPropertyValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer
        ProxyOverride = Get-ItemPropertyValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride
    }
}

<#
    .DESCRIPTION
    Reads the content of binary proxy settings from Windows registry
#>
function Get-BinaryConfig {
    [PSCustomObject]@{
        DefaultConnectionSettings = Get-ItemPropertyValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name DefaultConnectionSettings
        SavedLegacySettings = Get-ItemPropertyValue -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name SavedLegacySettings
    }
}

<#
    .DESCRIPTION
    Write new proxy config to the registry
#>
function Write-Config {
    params (
        $AutoConfigUrl,
        $ProxyEnable,
        $ProxyServer,
        $ProxyOverride,
        $DefaultConnectionSettings,
        $SavedLegacySettings
    )
}
