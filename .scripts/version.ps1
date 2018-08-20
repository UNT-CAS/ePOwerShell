<#
    .Synopsis
        Return the current version number for this project.
    .Description
        Return the current version number for this project.

        If in an AppVeyor build environment, the build number will be used in the version number.
    .Parameter Major
        Version major number.

        Not sure what I'm talking about? Try this code: `[version]'1.2.3.4'`.
    .Parameter Minor
        Version minor number.

        Not sure what I'm talking about? Try this code: `[version]'1.2.3.4'`.
    .Parameter Build
        Version build number.

        Not sure what I'm talking about? Try this code: `[version]'1.2.3.4'`.
    .Example
        $version = & .\version.ps1
    .Example
        # Override the major version number portion:

        $version = & .\version.ps1 -Major 1
#>
[CmdletBinding()]
param(
    [Parameter()]
    [int]
    $Major = $([version](Get-Content "$(Split-Path $PSScriptRoot -Parent)\.appveyor.yml" | Out-String | ConvertFrom-Yaml).version.Replace('.{build}', '')).Major
    ,
    [Parameter()]
    [int]
    $Minor = $([version](Get-Content "$(Split-Path $PSScriptRoot -Parent)\.appveyor.yml" | Out-String | ConvertFrom-Yaml).version.Replace('.{build}', '')).Minor
    ,
    [Parameter()]
    [int]
    $Build = $(if ($env:APPVEYOR_BUILD_NUMBER) { $env:APPVEYOR_BUILD_NUMBER } else { 0 })
)
$ErrorActionPreference = 'Stop'


$Version = [version]('{0}.{1}.{2}' -f $Major, $Minor, $Build)

if ($env:CI -and $env:APPVEYOR) {
    $env:APPVEYOR_BUILD_VERSION = $Version
}

return $Version