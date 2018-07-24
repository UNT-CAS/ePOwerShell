<#
    .Synopsis
        Extract Codecov.exe from the ZIP file.
    .Description
        PSDepend can't run complex tasks, and currently can't extract a FileDownload that's a ZIP file.
#>
$ErrorActionPreference = 'Stop'

$PSScriptRootParent = Split-Path $PSScriptRoot -Parent



# Enable TLS v1.2 (for GitHub et al.)
Write-Verbose "[REQUIREMENTS Prep] SecurityProtocol OLD: $([System.Net.ServicePointManager]::SecurityProtocol)"
[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
Write-Verbose "[REQUIREMENTS Prep] SecurityProtocol NEW: $([System.Net.ServicePointManager]::SecurityProtocol)"



# Set Version
Write-Verbose "[REQUIREMENTS Prep] APPVEYOR_BUILD_VERSION OLD: ${env:APPVEYOR_BUILD_VERSION}"
$Version = & "${PSScriptRoot}\version.ps1"
Write-Verbose "[REQUIREMENTS Prep] Version: ${Version}"
Write-Verbose "[REQUIREMENTS Prep] APPVEYOR_BUILD_VERSION NEW: ${env:APPVEYOR_BUILD_VERSION}"



# Create Temp Directory
$New_Item = @{
    ItemType = 'Directory'
    Path     = "${PSScriptRootParent}\.temp"
    Force    = $true
}
Write-Verbose "[REQUIREMENTS Prep] New-Item: $($New_Item | ConvertTo-Json -Compress)"
New-Item @New_Item | Out-Null