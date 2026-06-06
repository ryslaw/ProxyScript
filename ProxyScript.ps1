[CmdletBinding()]
param (
    [string]$AutoConfigUrl,
    [string]$ProxyServer,
    [string]$ProxyOverride,
    [switch]$ProxyServerEnable,
    [switch]$AutoConfigUrlEnable,
    [switch]$AutoDetectEnable
)

[Flags()] enum ProxyOption {
    CtrlBit    = 1 # must be always set
    Proxy      = 2
    AutoConfig = 4
    AutoDetect = 8
}

class ProxyConfiguration {
    [string] $AutoConfigUrl
    [string] $ProxyServer
    [string] $ProxyOverride
    [int] $BlobVersion
    # $OptionFlags
    [bool] $ProxyEnabled
    [bool] $AutoDetectEnabled
    [bool] $AutoConfigUrlEnabled

    [void] FromBlob($BinaryData) {
        if ([System.BitConverter]::ToUInt32($BinaryData, 0) -ne 70) {
            Write-Error "Input data should start with 70 (0x46)"
            exit
        }
        $this.BlobVersion = [System.BitConverter]::ToUInt32($BinaryData, 4)
        Write-Debug "`$BlobVersion = $this.BlobVersion"
        # $this.OptionFlags = [System.BitConverter]::ToUInt32($BinaryData, 8)
        $this.SetOptionFlags([System.BitConverter]::ToUInt32($BinaryData, 8))
        Write-Debug "`$OptionFlags = $($this.GetOptionFlags())"
        $Offset = 12
        Write-Debug "`$Offset = $Offset"

        if (-not $this.GetOptionFlags() -band 1) {
            # return $false # TODO: To be reconsidered
            exit
        }
        $ProxyServerLength = [System.BitConverter]::ToUInt32($BinaryData, $Offset)
        Write-Debug "`$ProxyServerLength = $ProxyServerLength"
        $Offset += 4
        Write-Debug "`$Offset = $Offset"
        if ($ProxyServerLength) {
            $this.ProxyServer = [System.Text.Encoding]::UTF8.GetString($BinaryData, $Offset, ($ProxyServerLength))
            Write-Debug "`$ProxyServer = $($this.ProxyServer)"
            $Offset += $ProxyServerLength
            Write-Debug "`$Offset = $Offset"
        }

        $ProxyOverrideLength = [System.BitConverter]::ToUInt32($BinaryData, $Offset)
        Write-Debug "`$ProxyOverrideLength = $ProxyOverrideLength"
        $Offset += 4
        Write-Debug "`$Offset = $Offset"
        if ($ProxyOverrideLength) {
            $this.ProxyOverride = [System.Text.Encoding]::UTF8.GetString($BinaryData, $Offset, ($ProxyOverrideLength))
            Write-Debug "`$ProxyOverride = $($this.ProxyOverride)"
            $Offset += $ProxyOverrideLength
            Write-Debug "`$Offset = $Offset"
        }

        $AutoConfigUrlLength = [System.BitConverter]::ToUInt32($BinaryData, $Offset)
        Write-Debug "`$AutoConfigUrlLength = $AutoConfigUrlLength"
        $Offset += 4
        Write-Debug "`$Offset = $Offset"
        if ($AutoConfigUrlLength) {
            $this.AutoConfigUrl = [System.Text.Encoding]::UTF8.GetString($BinaryData, $Offset, ($AutoConfigUrlLength))
            Write-Debug "`$AutoConfigUrl = $($this.AutoConfigUrl)"
            $Offset += $AutoConfigUrlLength
            Write-Debug "`$Offset = $Offset"
        }
    }

    [Byte[]] ToBlob() {
        $MemoryStream = [System.IO.MemoryStream]::new()
        $BinaryWriter = [System.IO.BinaryWriter]::new($MemoryStream)
        try {
            $BinaryWriter.Write([int32]70)
            $BinaryWriter.Write([int32]$this.BlobVersion)
            $BinaryWriter.Write([int32]$this.OptionFlags)

            if ($this.ProxyServer) {
                $BinaryWriter.Write([int32]($this.ProxyServer.Length))
                $ProxyServerBytes = [System.Text.Encoding]::UTF8.GetBytes($this.ProxyServer)
                $BinaryWriter.Write($ProxyServerBytes)
            }
            else {
                $BinaryWriter.Write([int32]0)
            }

            if ($this.ProxyOverride) {
                $BinaryWriter.Write([int32]($this.ProxyOverride.Length))
                $ProxyOverrideBytes = [System.Text.Encoding]::UTF8.GetBytes($this.ProxyOverride)
                $BinaryWriter.Write($ProxyOverrideBytes)
            }
            else {
                $BinaryWriter.Write([int32]0)
            }

            if ($this.AutoConfigUrl) {
                $BinaryWriter.Write([int32]($this.AutoConfigUrl.Length))
                $AutoConfigUrlBytes = [System.Text.Encoding]::UTF8.GetBytes($this.AutoConfigUrl)
                $BinaryWriter.Write($AutoConfigUrlBytes)
            }
            else {
                $BinaryWriter.Write([int32]0)
            }

            $padding = [byte[]]::new(32)
            $BinaryWriter.Write($padding)

            $BinaryWriter.Flush()

            # return ,$MemoryStream.ToArray()
            return $MemoryStream.ToArray()
        }
        finally {
            $binaryWriter.Dispose()
            $memoryStream.Dispose()
        }
    }

    [string] ToHexString() {
        return [System.BitConverter]::ToString($this.ToBlob()).Replace('-', '')
    }

    [void] FromHexString($HexString) {
        $CleanHex = $HexString -replace '[\s\-]', '' -replace '^0x', ''
        if ($CleanHex.Length % 2 -ne 0) {
            Write-Error "Incorrect string length"
            exit
        }
        $byteArray = [byte[]]::new($CleanHex.Length / 2)
        for ($i = 0; $i -lt $CleanHex.Length; $i += 2) {
            $byteString = $CleanHex.Substring($i, 2)
            $byteArray[$i / 2] = [System.Convert]::ToByte($byteString, 16)
        }
    }

    [ProxyOption] GetOptionFlags() {
        $Flags = [ProxyOption]::CtrlBit
        if ($this.AutoDetectEnable) { $Flags += [ProxyOption]::AutoDetect }
        if ($this.AutoConfigUrlEnable) { $Flags += [ProxyOption]::AutoConfig }
        if ($this.ProxyServerEnable) { $Flags += [ProxyOption]::Proxy }
        return $Flags
    }

    [void] SetOptionFlags([ProxyOption]$Flags) {
        $this.ProxyEnabled = $Flags.HasFlag([ProxyOption]::Proxy)
        $this.AutoDetectEnabled = $Flags.HasFlag([ProxyOption]::AutoDetect)
        $this.AutoConfigUrlEnabled = $Flags.HasFlag([ProxyOption]::AutoConfig)
    }

    [bool] Validate() {
        return $false
    }

    [void] Backup() {
        
    }

    [void] Restore() {

    }
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

# <#
#     .DESCRIPTION
#     Converts an object read from REG_BINARY registry values to a PS object
# #>
# function Convert-BlobToObject {
#     [CmdletBinding()]
#     param (
#         $BinaryData
#     )

#     if ([System.BitConverter]::ToUInt32($BinaryData, 0) -ne 70) {
#         Write-Debug "Input data should start with 70 (0x46)"
#         break
#     }
#     $BlobVersion = [System.BitConverter]::ToUInt32($BinaryData, 4)
#     Write-Debug "`$BlobVersion = $BlobVersion"
#     $OptionFlags = [System.BitConverter]::ToUInt32($BinaryData, 8)
#     Write-Debug "`$OptionFlags = $OptionFlags"
#     $Offset = 12
#     Write-Debug "`$Offset = $Offset"

#     if (-not $OptionFlags -band 1) {
#         return $false # TODO: To be reconsidered
#     }
#     $ProxyServerLength = [System.BitConverter]::ToUInt32($BinaryData, $Offset)
#     Write-Debug "`$ProxyServerLength = $ProxyServerLength"
#     $Offset += 4
#     Write-Debug "`$Offset = $Offset"
#     if ($ProxyServerLength) {
#         $ProxyServer = [System.Text.Encoding]::UTF8.GetString($BinaryData, $Offset, ($ProxyServerLength))
#         Write-Debug "`$ProxyServer = $ProxyServer"
#         $Offset += $ProxyServerLength
#         Write-Debug "`$Offset = $Offset"
#     }

#     $ProxyOverrideLength = [System.BitConverter]::ToUInt32($BinaryData, $Offset)
#     Write-Debug "`$ProxyOverrideLength = $ProxyOverrideLength"
#     $Offset += 4
#     Write-Debug "`$Offset = $Offset"
#     if ($ProxyOverrideLength) {
#         $ProxyOverride = [System.Text.Encoding]::UTF8.GetString($BinaryData, $Offset, ($ProxyOverrideLength))
#         Write-Debug "`$ProxyOverride = $ProxyOverride"
#         $Offset += $ProxyOverrideLength
#         Write-Debug "`$Offset = $Offset"
#     }

#     $AutoConfigUrlLength = [System.BitConverter]::ToUInt32($BinaryData, $Offset)
#     Write-Debug "`$AutoConfigUrlLength = $AutoConfigUrlLength"
#     $Offset += 4
#     Write-Debug "`$Offset = $Offset"
#     if ($AutoConfigUrlLength) {
#         $AutoConfigUrl = [System.Text.Encoding]::UTF8.GetString($BinaryData, $Offset, ($AutoConfigUrlLength))
#         Write-Debug "`$AutoConfigUrl = $AutoConfigUrl"
#         $Offset += $AutoConfigUrlLength
#         Write-Debug "`$Offset = $Offset"
#     }

#     [PSCustomObject]@{
#         # AutoDetect = [bool]($OptionFlags -band 8) # should not be returned
#         # AutoConfigUrlEnabled = [bool]($OptionFlags -band 4) # should not be returned
#         AutoConfigUrl = $AutoConfigUrl
#         # ProxyEnabled = [bool]($OptionFlags -band 2) # should not be returned
#         ProxyServer = $ProxyServer
#         ProxyOverride = $ProxyOverride
#         BlobVersion = $BlobVersion
#         OptionFlags = $OptionFlags
#     }
# }

<#
    .DESCRIPTION
    Converts a PS object to hex string
#>
function Convert-ObjectToHexString {}

# <#
#     .DESCRIPTION
#     Converts a PS object to an object ready to be put to the Windows registry as a REG_BINARY value
# #>
# function Convert-ObjectToBlob {
#     [CmdletBinding()]
#     param (
#         $AutoConfigUrl = '',
#         $ProxyServer = '',
#         $ProxyOverride = '',
#         $BlobVersion = 0,
#         $OptionFlags = 1
#     )

#     $MemoryStream = [System.IO.MemoryStream]::new()
#     $BinaryWriter = [System.IO.BinaryWriter]::new($MemoryStream)
#     try {
#         $BinaryWriter.Write([int32]70)
#         $BinaryWriter.Write([int32]$BlobVersion)
#         $BinaryWriter.Write([int32]$OptionFlags)

#         if ($ProxyServer) {
#             $BinaryWriter.Write([int32]($ProxyServer.Length))
#             $ProxyServerBytes = [System.Text.Encoding]::UTF8.GetBytes($ProxyServer)
#             $BinaryWriter.Write($ProxyServerBytes)
#         }
#         else {
#             $BinaryWriter.Write([int32]0)
#         }

#         if ($ProxyOverride) {
#             $BinaryWriter.Write([int32]($ProxyOverride.Length))
#             $ProxyOverrideBytes = [System.Text.Encoding]::UTF8.GetBytes($ProxyOverride)
#             $BinaryWriter.Write($ProxyOverrideBytes)
#         }
#         else {
#             $BinaryWriter.Write([int32]0)
#         }

#         if ($AutoConfigUrl) {
#             $BinaryWriter.Write([int32]($AutoConfigUrl.Length))
#             $AutoConfigUrlBytes = [System.Text.Encoding]::UTF8.GetBytes($AutoConfigUrl)
#             $BinaryWriter.Write($AutoConfigUrlBytes)
#         }
#         else {
#             $BinaryWriter.Write([int32]0)
#         }

#         $padding = [byte[]]::new(32)
#         $BinaryWriter.Write($padding)

#         $BinaryWriter.Flush()
#         return ,$MemoryStream.ToArray()
#     }
#     finally {
#         $binaryWriter.Dispose()
#         $memoryStream.Dispose()
#     }
# }

<#
    .DESCRIPTION
    Reads the content of text proxy settings from Windows registry
#>
function Get-TextConfig {
    try { $AutoConfigUrl = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl } catch { $AutoConfigUrl = '' }
    try { $ProxyEnable = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable } catch { $ProxyEnable = '' }
    try { $ProxyServer = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer } catch { $ProxyServer = '' }
    try { $ProxyOverride = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride } catch { $ProxyOverride = '' }
    try { $ProxySettingsPerUser = Get-ItemPropertyValue -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxySettingsPerUser } catch { $ProxySettingsPerUser = '' }
    [PSCustomObject]@{
        AutoConfigUrl = $AutoConfigUrl
        ProxyEnable = $ProxyEnable
        ProxyServer = $ProxyServer
        ProxyOverride = $ProxyOverride
        ProxySettingsPerUser = $ProxySettingsPerUser
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
    [CmdletBinding()]
    param (
        $AutoDetect = 0,
        $AutoConfigUrl = '',
        $ProxyEnable = 0,
        $ProxyServer = '',
        $ProxyOverride = '',
        $DefaultConnectionSettings,
        $SavedLegacySettings
    )

    if ($AutoConfigUrl) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl -Value $AutoConfigUrl -Type String
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl -Value $AutoConfigUrl -Type String
    }
    else {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name AutoConfigUrl -ErrorAction SilentlyContinue
    }

    if ($ProxyServer) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value $ProxyServer -Type String
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -Value $ProxyServer -Type String
    }
    else {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyServer -ErrorAction SilentlyContinue
    }

    if ($ProxyOverride) {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value $ProxyOverride -Type String
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -Value $ProxyOverride -Type String
    }
    else {
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyOverride -ErrorAction SilentlyContinue
    }
    
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value $ProxyEnable -Type DWord
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings" -Name ProxyEnable -Value $ProxyEnable -Type DWord

    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name DefaultConnectionSettings -Value $DefaultConnectionSettings -Type Binary
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name SavedLegacySettings -Value $SavedLegacySettings -Type Binary
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name DefaultConnectionSettings -Value $DefaultConnectionSettings -Type Binary
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Internet Settings\Connections" -Name SavedLegacySettings -Value $SavedLegacySettings -Type Binary
}

# $AutoConfigUrl = ""
# $ProxyServer = "10.0.0.16:3128"
# $ProxyEnable = 1
# $ProxyOverride = "<local>" 
# $OptionFlags = 3

$Proxy = [ProxyConfiguration]@{
    AutoConfigUrl       = $AutoConfigUrl
    ProxyServer         = $ProxyServer
    ProxyOverride       = $ProxyOverride
    ProxyServerEnable   = $ProxyServerEnable
    AutoConfigUrlEnable = $AutoConfigUrlEnable
    AutoDetectEnable    = $AutoDetectEnable
}

$parameters = @{
    ProxyEnable = 0
}
$Proxy.OptionFlags = [ProxyOption]::CtrlBit
if ($AutoConfigUrl) { $parameters.AutoConfigUrl = $AutoConfigUrl }
if ($ProxyServer) { $parameters.ProxyServer = $ProxyServer }
if ($ProxyOverride) { $parameters.ProxyOverride = $ProxyOverride }
if ($AutoDetectEnable) { $Proxy.OptionFlags += [ProxyOption]::AutoDetect }
if ($AutoConfigUrlEnable) { $Proxy.OptionFlags += [ProxyOption]::AutoConfig }
if ($ProxyServerEnable) { 
    $Proxy.OptionFlags += [ProxyOption]::Proxy
    $parameters.ProxyEnable = 1
}

"# Current config:"
Get-TextConfig

# $BinaryConf = Convert-ObjectToBlob -AutoConfigUrl $AutoConfigUrl -ProxyServer $ProxyServer -ProxyOverride $ProxyOverride -OptionFlags $OptionFlags
$BinaryConf = $Proxy.ToBlob()
$Proxy.ToHexString()
$parameters.DefaultConnectionSettings = $BinaryConf
$parameters.SavedLegacySettings = $BinaryConf
# Write-Config -AutoConfigUrl $AutoConfigUrl -ProxyEnable $ProxyEnable -ProxyServer $ProxyServer -ProxyOverride $ProxyOverride -DefaultConnectionSettings $BinaryConf -SavedLegacySettings $BinaryConf
# $parameters
# Write-Config @parameters

"# New config:"
# Get-TextConfig
$Proxy