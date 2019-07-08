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
$script:ManifestJsonFile = "${PSScriptRootParent}\Manifest.json"
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

    $script:Manifest.Copyright = $script:Manifest.Copyright -f [DateTime]::Now.Year
    $script:Manifest.GUID = (New-Guid).Guid

    $script:Manifest_ModuleName = $script:Manifest.ModuleName
    $script:Manifest.Remove('ModuleName')

    $script:ParentModulePath = "${script:BuildOutput}\${script:Manifest_ModuleName}"

    $PSModulePath1 = $env:PSModulePath.Split(';')[1]
    $script:SystemModuleLocation = "${PSModulePath1}\${script:Manifest_ModuleName}"

    $script:Version = [string](& "${PSScriptRootParent}\.scripts\version.ps1")
}


Task default -Depends CompressModule

Task Clean -Description 'Cleans the build environment' {
    if (Test-Path $ParentModulePath) {
        if ((Get-ChildItem $ParentModulePath | Measure-Object).Count -ne 0) {
            Remove-Item "$ParentModulePath\*" -Recurse -Force
        }
    } else {
        New-Item -ItemType Directory -Path $ParentModulePath -Force
    }

    if (Get-Module -Name $script:thisModuleName) {
        Remove-Module -Name $script:thisModuleName -Force
    }
}

Task CompileManifest -Description 'Created the module .psd1 manifest file' -Depends Clean {
    $script:Manifest.Path = "${script:ParentModulePath}\${script:Manifest_ModuleName}.psd1"
    if ($env:APPVEYOR_REPO_TAG -eq 'true') {
        try {
            [Version] $env:APPVEYOR_REPO_TAG_NAME
            $script:Manifest.ModuleVersion = $env:APPVEYOR_REPO_TAG_NAME
        } catch {
            $script:Manifest.ModuleVersion = $script:Version
        }
    } else {
        $script:Manifest.ModuleVersion = $script:Version
    }
    Write-Host "[BUILD SetupModule] New-ModuleManifest: $($script:Manifest | ConvertTo-Json -Compress)" -ForegroundColor Magenta
    New-ModuleManifest @script:Manifest
}


Task PSScriptAnalyzer -Description 'Runs PSScriptAnalyzer against compiled module' -Depends Clean {
    $PSSAResults = Invoke-ScriptAnalyzer -Path "${PSScriptRootParent}\${thisModuleName}" -Settings "${script:PSScriptRootParent}\PSScriptAnalyzerSettings.psd1" -Recurse

    $Information = $PSSAResults | Where-Object { $_.Severity -eq 'Information' }
    $Errors = $PSSAResults | Where-Object { $_.Severity -eq 'Error' }
    $Warnings = $PSSAResults | Where-Object { $_.Severity -eq 'Warning' }
    $ParseErrors = $PSSAResults | Where-Object { $_.Severity -eq 'ParseError' }

    if ($Information) {
        Write-Host "PSSA Information:"
        $Information
    }

    if ($Warnings) {
        Write-Host "PSSA Warnings:"
        $Warnings
    }

    if ($Errors) {
        Write-Error "PSSA Errors"
        Throw $Errors
    } elseif ($ParseErrors) {
        Write-Error "PSSA Parse Errors"
        Throw $ParseErrors
    }
}

Task CompileModule -Description 'Compiles all funcitons into a single .psm1 file' -Depends PSScriptAnalyzer {
    $ModuleManifest = "${script:ParentModulePath}\${script:Manifest_ModuleName}.psm1"
    $Files = Get-ChildItem -Path "${PSScriptRootParent}\${thisModuleName}" -Recurse -File
    $FileContents = foreach ($File in $Files) {
        Get-Content $File.FullName -Force
    }

    $FileContents | Out-File -FilePath $ModuleManifest -Force
}

Task ImportModule -Description 'Imports the compiled module' -Depends CompileModule, CompileManifest {
    Import-Module "${script:ParentModulePath}\${script:Manifest_ModuleName}.psm1"
}

Task InvokePester -Description 'Runs Pester tests against compiled module' -Depends ImportModule {
    $InvokePester = @{
        Path         = "${PSScriptRootParent}\Tests\"
        CodeCoverage = "${script:ParentModulePath}\${script:Manifest_ModuleName}.psm1"
        PassThru     = $True
        OutputFormat = 'NUnitXml'
        OutputFile   = ([IO.FileInfo] '{0}\dev\CodeCoverage.xml' -f $PSScriptRootParent)
    }

    $Pester = Invoke-Pester @InvokePester

    if ($Pester.FailedCount -gt 0) {
        Throw "$($Pester.FailedCount) tests failed."
    }
}

Task CompressModule -Description "Compress module for easy download from GitHub" -Depends InvokePester {
    Write-Host "[BUILD CompressModule] Import-Module ${env:Temp}\CodeCovIo.psm1" -ForegroundColor Magenta
    Compress-Archive -Path $script:ParentModulePath -DestinationPath "${script:ParentModulePath}.zip"

    Push-AppveyorArtifact (Resolve-Path "${script:ParentModulePath}.zip")
}