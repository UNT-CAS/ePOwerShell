<#
    Deployed with PSDeploy
        - https://github.com/RamblingCookieMonster/PSDeploy
#>
$PSScriptRootParent = Split-Path $PSScriptRoot -Parent
Write-Host "[Deploy] PSScriptRootParent: ${PSScriptRootParent}" -Foregroundcolor 'Blue' -BackgroundColor 'Magenta'
Write-Host "[Deploy] APPVEYOR_PROJECT_NAME: ${env:APPVEYOR_PROJECT_NAME}" -Foregroundcolor 'Blue' -BackgroundColor 'Magenta'
Write-Host "[Deploy] APPVEYOR_REPO_TAG: ${env:APPVEYOR_REPO_TAG}" -Foregroundcolor 'Blue' -BackgroundColor 'Magenta'
Write-Host "[Deploy] APPVEYOR_REPO_BRANCH: ${env:APPVEYOR_REPO_BRANCH}" -Foregroundcolor 'Blue' -BackgroundColor 'Magenta'

if (
    ($env:APPVEYOR_REPO_TAG -eq 'true') -and
    ($env:APPVEYOR_REPO_BRANCH -eq 'master')
) {
    Write-Host "Deploying to PSGallery"
    Deploy Module {
        By PSGalleryModule ePOwerShell {
            FromSource "${PSScriptRootParent}\dev\BuildOutput\ePOwerShell"
            To PSGallery
            WithOptions @{
                ApiKey = $env:PSGalleryApiKey
            }
        }
    }
}