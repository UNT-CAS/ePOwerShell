[System.String]    $ProjectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $PesterFile           = [IO.FileInfo] ([System.String] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $ProjectRoot          = Split-Path -Parent $PesterFile.Directory
[IO.DirectoryInfo] $ProjectDirectory     = Join-Path -Path $ProjectRoot -ChildPath $ProjectDirectoryName -Resolve
[IO.FileInfo]      $TestFile             = Join-Path -Path $ProjectDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.ps1', '.psm1') -Resolve

$ErrorActionPreference = 'SilentlyContinue'

Describe $TestFile.Name {
    It 'Import-Module' {
        { Import-Module $TestFile } | Should Not Throw
    }

    It 'Imported' {
        Get-Module $ProjectDirectoryName | Should Not BeNullOrEmpty
    }

    $Public, $Private = @( Get-ChildItem -Path "${ProjectDirectory}\Public\*.ps1" ), @( Get-ChildItem -Path "${ProjectDirectory}\Private\*.ps1" )

    Context 'Public Functions' {
        foreach ($File in $Public) {
            It "Exists: $($File.BaseName)" {
                Get-Command $File.BaseName | Should Not BeNullOrEmpty
            }
        }
    }

    Context 'Private Functions' {
        foreach ($File in $Private) {
            It "Not Exists: $($File.BaseName)" {
                Get-Command $File.BaseName | Should BeNullOrEmpty
            }
        }
    }
}