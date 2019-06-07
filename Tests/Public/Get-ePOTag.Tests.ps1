[System.String]    $ProjectDirectoryName = 'ePOwerShell'
[System.String]    $FunctionType         = 'Public'
[IO.FileInfo]      $PesterFile           = [IO.FileInfo] ([System.String] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[System.String]    $FunctionName         = $PesterFile.Name.Split('.')[0]
[IO.DirectoryInfo] $ProjectRoot          = Split-Path -Parent $PesterFile.Directory

While (-not ($ProjectRoot.Name -eq $ProjectDirectoryName)) {
    $ProjectRoot = Split-Path -Parent $ProjectRoot.FullName
}

[IO.DirectoryInfo] $ProjectDirectory     = Join-Path -Path $ProjectRoot -ChildPath $ProjectDirectoryName -Resolve
[IO.DirectoryInfo] $PublicDirectory      = Join-Path -Path $ProjectDirectory -ChildPath 'Public' -Resolve
[IO.DirectoryInfo] $PrivateDirectory     = Join-Path -Path $ProjectDirectory -ChildPath 'Private' -Resolve
[IO.DirectoryInfo] $ClassesDirectory     = Join-Path -Path $ProjectDirectory -ChildPath 'Classes' -Resolve
[IO.DirectoryInfo] $ExampleDirectory     = Join-Path (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -ChildPath $FunctionType -Resolve
[IO.DirectoryInfo] $ExampleDirectory     = Join-Path $ExampleDirectory.FullName -ChildPath $FunctionName -Resolve
[IO.DirectoryInfo] $ReferenceDirectory   = Join-Path $ExampleDirectory.FullName -ChildPath 'References' -Resolve
if ($FunctionType -eq 'Private') {
    [IO.FileInfo]  $TestFile             = Join-Path -Path $PrivateDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.', '.') -Resolve
} else {
    [IO.FileInfo]  $TestFile             = Join-Path -Path $PublicDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.', '.') -Resolve
}

. $TestFile
Get-ChildItem -Path $PublicDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }
Get-ChildItem -Path $PrivateDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }
Get-ChildItem -Path $ClassesDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }



$Examples = Get-ChildItem $ExampleDirectory -Filter "$($TestFile.BaseName).*.psd1" -File
$Tests = foreach ($Example in $Examples) {
    [hashtable] $Test = @{
        Name = $Example.BaseName.Replace("$($TestFile.BaseName).$verb", '').Replace('_', ' ')
    }
    Write-Verbose "Test: $($Test | ConvertTo-Json)"

    foreach ($ExampleData in (Import-PowerShellDataFile -LiteralPath $Example.FullName).GetEnumerator()) {
        $Test.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"
    Write-Output $Test
}



Describe $TestFile.Name {
    foreach ($Test in $Tests) {
        Mock Invoke-ePORequest {
            if ($Test.Output.Throws) {
                return $Null
            } else {
                if ($Query.searchText) {
                    $Files = foreach ($Item in $Query.searchText) {
                        Get-ChildItem $ReferenceDirectory -Filter ('{0}.html' -f $Item)
                    }
                } else {
                    $Files = Get-ChildItem $ReferenceDirectory -Filter 'AllTags.html'
                }
            }

            foreach ($File in $Files) {
                Write-Output (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
            }
        }

        Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

        Context $Test.Name {
            [hashtable] $Parameters = $test.Parameters

            if ($Test.Parameters) {
                It "Get-ePOTag with tags" {
                    { $script:RequestResponse = Get-ePOTag @Parameters } | Should Not Throw
                }
            } elseif ($Test.Pipelined) {
                if ($Test.UseePOTag) {
                    It "Get-ePOTag from pipeline" {
                        { $script:RequestResponse = $Parameters.Tag | Get-ePOTag } | Should Not Throw
                    }
                } else {
                    It "Get-ePOTag from pipeline" {
                        { $script:RequestResponse = $Parameters.Tag | Get-ePOTag } | Should Not Throw
                    }
                }
            } else {
                It "Get-ePOTag" {
                    { $script:RequestResponse = Get-ePOTag } | Should Not Throw
                }
            }

            if ($Test.Output.Throws) {
                It "Get-ePOTag: Should not return anything" {
                    $script:RequestResponse | Should BeNullOrEmpty
                }
            } else {
                It "Output Type: $($Test.Output.Type)" {
                    if ($Test.Output.Type -eq 'System.Void') {
                        $script:RequestResponse | Should BeNullOrEmpty
                    } else {
                        $script:RequestResponse.GetType().FullName | Should Be $Test.Output.Type
                    }
                }

                foreach ($Tag in $script:RequestResponse) {
                    It "Item is an ePOTag object" {
                        $Tag.GetType().FullName | Should Be 'ePOTag'
                    }
                }
            }
        }
    }
}