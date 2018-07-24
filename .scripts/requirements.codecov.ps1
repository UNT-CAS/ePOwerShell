<#
    .Synopsis
        Extract Codecov.exe from the ZIP file.
    .Description
        PSDepend can't run complex tasks, and currently can't extract a FileDownload that's a ZIP file.
#>
$ErrorActionPreference = 'Stop'

$PSScriptRootParent = Split-Path $PSScriptRoot -Parent



$Move_Item = @{
    LiteralPath     = "${PSScriptRootParent}\.temp\CodeCovIo.psm1"
    Destination     = $env:Temp
    Force           = $true
}
Write-Verbose "[REQUIREMENTS Codecov] Move-Item: $($Move_Item | ConvertTo-Json -Compress)"
Move-Item @Move_Item



$Move_Item = @{
    LiteralPath     = "${PSScriptRootParent}\.temp\Codecov.zip"
    Destination     = $env:Temp
    Force           = $true
}
Write-Verbose "[REQUIREMENTS Codecov] Move-Item: $($Move_Item | ConvertTo-Json -Compress)"
Move-Item @Move_Item



$Expand_Archive = @{
    LiteralPath     = "${env:Temp}\Codecov.zip"
    DestinationPath = $env:Temp
    Force           = $true
}
Write-Verbose "[REQUIREMENTS Codecov] Expand-Archive: $($Expand_Archive | ConvertTo-Json -Compress)"
Expand-Archive @Expand_Archive