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
    Reads the content of text proxy settings from Windows registry
#>
function Read-TextConfig {}

<#
    .DESCRIPTION
    Reads the content of binary proxy settings from Windows registry
#>
function Read-BinaryConfig {}

<#
    .DESCRIPTION
    Write new proxy config to the registry
#>
function Write-Config {}
