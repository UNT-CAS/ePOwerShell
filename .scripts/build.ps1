<#
    .Synopsis
        Prepare this machine; *installing* this module in a location accessible by DSC.

    .Description
        Uses [psake](https://github.com/psake/psake) to prepare this machine; *installing* this module in a location accessible by DSC.

        May do different tasks depending on the environment it's running in. Read the code for the details on that.
    .Example
        # Run this Build Script:
        
        Invoke-psake .\.build.ps1
    .Example
        # Skip Bootstrap

        Invoke-psake .\.build.ps1 -Properties @{'SkipBootstrap'=$true}
    .Example
        # Run this Build Script with different parameters/properties 'thisModuleName':

        Invoke-psake .\.build.ps1 -Properties @{'thisModuleName'='OtherModuleName'}
    .Example
        # Run this Build Script with a parameters/properties that's not otherwise defined:
        
        Invoke-psake .\.build.ps1 -Properties @{'Version'=[version]'1.2.3'}
#>
$ErrorActionPreference = 'Stop'

$script:thisModuleName = 'ePOwerShell'
$script:PSScriptRootParent = Split-Path $PSScriptRoot -Parent
$script:ManifestJsonFile = "${PSScriptRootParent}\${thisModuleName}\Manifest.json"
$script:BuildOutput = "${PSScriptRootParent}\dev\BuildOutput"

$script:Manifest = @{}
$Manifest_obj = Get-Content $script:ManifestJsonFile | ConvertFrom-Json
$Manifest_obj | Get-Member -MemberType Properties | ForEach-Object { $script:Manifest.Set_Item($_.Name, $Manifest_obj.($_.Name)) }

$script:Manifest_ModuleName = $null
$script:ParentModulePath = $null
$script:ResourceModulePath = $null
$script:SystemModuleLocation = $null
$script:DependsBootstrap = if ($Properties.Keys -contains 'SkipBootstrap' -and $Properties.SkipBootstrap) { $null } else { 'Bootstrap' }
$script:VersionBuild = $null

if (-not $env:CI) {
    Get-Module $Manifest.ModuleName -ListAvailable -Refresh | Uninstall-Module -Force -ErrorAction 'SilentlyContinue'
    (Get-Module $Manifest.ModuleName -ListAvailable -Refresh).ModuleBase | Remove-Item -Recurse -Force -ErrorAction 'SilentlyContinue'
}

if (($env:CI -ne 'True') -and ($env:APPVEYOR -ne 'True')) {
    function Push-AppveyorArtifact { param($FileName) Write-Host "[BUILD Push-AppveyorArtifact] Not in AppVeyor; skipping ..." -ForegroundColor Magenta }
    function Add-AppveyorMessage { param($Message) Write-Host "[BUILD Add-AppveyorMessage] ${Message}" -ForegroundColor Magenta }
}

Write-Host "[BUILD] Properties Keys: $($Properties.Keys -join ', ')" -ForegroundColor Magenta
Write-Host "[BUILD] Properties.SkipBootstrap: $($Properties.SkipBootstrap)" -ForegroundColor Magenta
Write-Host "[BUILD] DependsBootstrap: ${script:DependsBootstrap}" -ForegroundColor Magenta

# Parameters:
Properties {
    $thisModuleName = $script:thisModuleName
    $PSScriptRootParent = $script:PSScriptRootParent
    $ManifestJsonFile = $script:ManifestJsonFile
    $BuildOutput = $script:BuildOutput

    # Manipulate the Parameters for usage:
    
    $script:Manifest.Copyright = $script:Manifest.Copyright -f [DateTime]::Now.Year

    $script:Manifest_ModuleName = $script:Manifest.ModuleName
    $script:Manifest.Remove('ModuleName')

    $script:ParentModulePath = "${script:BuildOutput}\${script:Manifest_ModuleName}"

    $PSModulePath1 = $env:PSModulePath.Split(';')[1]
    $script:SystemModuleLocation = "${PSModulePath1}\${script:Manifest_ModuleName}"

    $script:Version = [string](& "${PSScriptRootParent}\.scripts\version.ps1")
}

# Start psake builds
Task default -Depends CompressModule

<#
    Bootstrap PSDepend:
        - https://github.com/RamblingCookieMonster/PSDepend
    Install Dependencies
#>
Task Bootstrap -Description "Bootstrap & Run PSDepend" {
    $PSDepend = Get-Module -Name 'PSDepend'
    Write-Host "[BUILD Bootstrap] PSDepend: $($PSDepend.Version)" -ForegroundColor Magenta
    if ($PSDepend)
    {
        Write-Host "[BUILD Bootstrap] PSDepend: Updating..." -ForegroundColor Magenta
        $PSDepend | Update-Module -Force
    }
    else
    {
        Write-Host "[BUILD Bootstrap] PSDepend: Installing..." -ForegroundColor Magenta
        Install-Module -Name 'PSDepend' -Force
    }

    Write-Host "[BUILD Bootstrap] PSDepend: Installing..." -ForegroundColor Magenta
    $PSDepend = Import-Module -Name 'PSDepend' -PassThru
    Write-Host "[BUILD Bootstrap] PSDepend: $($PSDepend.Version)" -ForegroundColor Magenta

    Write-Host "[BUILD Bootstrap] PSDepend: Invoking '${PSScriptRootParent}\REQUIREMENTS.psd1'" -ForegroundColor Magenta
    Push-Location $PSScriptRootParent
    Invoke-PSDepend -Path "${PSScriptRootParent}\REQUIREMENTS.psd1" -Force
    Pop-Location
}

<#
    Preperation and Setup:
        - Import Manifest.json to create the PDS1 file.
        - Modify Manifest information; keeping purged information.
        - Establish Module/Resource Locations/Paths.
#>
Task SetupModule -Description "Prepare and Setup Module" -Depends $DependsBootstrap {
    New-Item -ItemType Directory -Path $script:ParentModulePath -Force

    $script:Manifest.Path = "${script:ParentModulePath}\${script:Manifest_ModuleName}.psd1"
    $script:Manifest.ModuleVersion = $script:Version
    Write-Host "[BUILD SetupModule] New-ModuleManifest: $($script:Manifest | ConvertTo-Json -Compress)" -ForegroundColor Magenta
    New-ModuleManifest @script:Manifest

    $copyItem = @{
        LiteralPath = "${PSScriptRootParent}\${script:thisModuleName}\${script:thisModuleName}.psm1"
        Destination = $script:ParentModulePath
        Force       = $true
    }
    Write-Host "[BUILD SetupModule] Copy-Item: $($copyItem | ConvertTo-Json -Compress)" -ForegroundColor Magenta
    Copy-Item @copyItem

    foreach ($directory in (Get-ChildItem "${PSScriptRootParent}\${thisModuleName}" -Directory)) {
        $copyItem = @{
            LiteralPath = $directory.FullName
            Destination = $script:ParentModulePath
            Recurse     = $true
            Force       = $true
        }
        Write-Host "[BUILD SetupModule] Copy-Item: $($copyItem | ConvertTo-Json -Compress)" -ForegroundColor Magenta
        Copy-Item @copyItem
    }
}

<#
    Put Module/Resource in locations accessible by DSC:
        - Create the PSD1 files from Manifest.
        - Copy PSM1 to location.
        - Copy Module to System Location; for testing.
#>
Task InstallModule -Description "Prepare and Setup/Install Module" -Depends SetupModule {
    $New_Item = @{
        ItemType = 'Directory'
        Path     = $script:SystemModuleLocation
        Force    = $true
    }
    Write-Host "[BUILD InstallModule] New-Item: $($New_Item | ConvertTo-Json -Compress)" -ForegroundColor Magenta
    New-Item @New_Item | Out-Null

    $Copy_Item = @{
        Path        = "${script:BuildOutput}\*"
        Destination = $script:SystemModuleLocation
        Recurse     = $true
        Force       = $true
    }
    Write-Host "[BUILD InstallModule] Copy-Item: $($Copy_Item | ConvertTo-Json -Compress)" -ForegroundColor Magenta
    Copy-Item @Copy_Item
}

<#
    Tests
        - Pester
        - CodeCov
#>
Task TestModule -Description "Run Pester Tests and CoeCoverage" -Depends InstallModule {
    Write-Host "[BUILD TestModule] Import-Module ${env:Temp}\CodeCovIo.psm1" -ForegroundColor Magenta
    Import-Module ${env:Temp}\CodeCovIo.psm1
    
    $invokePester = @{
        Path = "${PSScriptRootParent}\Tests"
        CodeCoverage = (Get-ChildItem "${PSScriptRootParent}\${thisModuleName}" -Recurse -Include '*.psm1', '*.ps1').FullName
        PassThru = $true
        OutputFormat = 'NUnitXml'
        OutputFile   = ([IO.FileInfo] '{0}\dev\CodeCoverage.xml' -f $PSScriptRootParent)
        EnableExit = $True
    }
    Write-Host "[BUILD TestModule] Invoke-Pester $($invokePester | ConvertTo-Json)" -ForegroundColor Magenta
    $res = Invoke-Pester @invokePester
    # Write-Host "[BUILD TestModule] Pester Result: $($res | ConvertTo-Json)" -ForegroundColor Magenta
    
    $exportCodeCovIoJson = @{
        CodeCoverage = $res.CodeCoverage
        RepoRoot     = $PSScriptRootParent
        Path         = ([string] $invokePester.OutputFile).Replace('.xml', '.json')
    }
    Write-Host "[BUILD TestModule] Export-CodeCovIoJson: $($exportCodeCovIoJson | ConvertTo-Json)" -ForegroundColor Magenta
    Export-CodeCovIoJson @exportCodeCovIoJson
    
    Write-Host "[BUILD TestModule] Uploading CodeCov.io Report ..." -ForegroundColor Magenta
    Push-Location $script:PSScriptRootParent
    & "${env:Temp}\Codecov\codecov.exe" -f $exportCodeCovIoJson.Path
    Pop-Location

    Write-Host "[BUILD TestModule] Adding Results to Artifacts..." -ForegroundColor Magenta
    # (New-Object 'System.Net.WebClient').UploadFile("https://ci.appveyor.com/api/testresults/nunit/${env:APPVEYOR_JOB_ID}", (Resolve-Path $invokePester.OutputFile))
    Push-AppveyorArtifact (Resolve-Path $invokePester.OutputFile)
    Push-AppveyorArtifact (Resolve-Path $exportCodeCovIoJson.Path)

    if ($res.FailedCount -gt 0) {
        Throw "$($res.FailedCount) tests failed."
        # $Host.SetShouldExit($res.FailedCount)
        Exit $res.FailedCount
    }
}

<#
    Compress things for releasing
#>
Task CompressModule -Description "Compress module for easy download from GitHub" -Depends TestModule {
    Write-Host "[BUILD CompressModule] Import-Module ${env:Temp}\CodeCovIo.psm1" -ForegroundColor Magenta
    Compress-Archive -Path $script:ParentModulePath -DestinationPath "${script:ParentModulePath}.zip"

    Push-AppveyorArtifact (Resolve-Path "${script:ParentModulePath}.zip")
}
