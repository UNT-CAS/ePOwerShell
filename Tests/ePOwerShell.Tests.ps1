[string]           $projectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $pesterFile = [io.fileinfo] ([string] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $projectRoot = Split-Path -Parent $pesterFile.Directory
[IO.DirectoryInfo] $projectDirectory = Join-Path -Path $projectRoot -ChildPath $projectDirectoryName -Resolve
[IO.FileInfo]      $testFile = Join-Path -Path $projectDirectory -ChildPath ($pesterFile.Name -replace '\.Tests\.ps1', '.psm1') -Resolve

Describe $testFile.Name {
    It 'Import-Module' {
        { Import-Module $testFile } | Should Not Throw
    }

    It 'Imported' {
        Get-Module $projectDirectoryName | Should Not BeNullOrEmpty
    }

    $public = @( Get-ChildItem -Path "${projectDirectory}\Public\*.ps1" -ErrorAction SilentlyContinue )

    Context 'Public Functions' {
        foreach ($file in $public) {
            It "Exists: $($file.BaseName)" {
                Get-Command $file.BaseName -ErrorAction SilentlyContinue | Should Not BeNullOrEmpty
            }
        }
    }

    $private = @( Get-ChildItem -Path "${projectDirectory}\Private\*.ps1" -ErrorAction SilentlyContinue )

    Context 'Private Functions' {
        foreach ($file in $Private) {
            It "Not Exists: $($file.BaseName)" {
                Get-Command $file.BaseName -ErrorAction SilentlyContinue | Should BeNullOrEmpty
            }
        }
    }
}