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
if ($FunctionType -eq 'Private') {
    [IO.FileInfo]  $TestFile             = Join-Path -Path $PrivateDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.', '.') -Resolve
} else {
    [IO.FileInfo]  $TestFile             = Join-Path -Path $PublicDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.', '.') -Resolve
}

. $TestFile
Get-ChildItem -Path $PublicDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }
Get-ChildItem -Path $PrivateDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }
Get-ChildItem -Path $ClassesDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }

[System.Collections.ArrayList] $tests = @()
$examples = Get-ChildItem $exampleDirectory -Filter "$($testFile.BaseName).*.psd1" -File

foreach ($example in $examples) {
    [hashtable] $test = @{
        Name = $example.BaseName.Replace("$($testFile.BaseName).$verb", '').Replace('_', ' ')
    }
    Write-Verbose "Test: $($test | ConvertTo-Json)"

    foreach ($exampleData in (Import-PowerShellDataFile -LiteralPath $example.FullName).GetEnumerator()) {
        $test.Add($exampleData.Name, $exampleData.Value) | Out-Null
    }

    if ($Test.ePOGroupObject) {
        $Test.Add('ePOGroup', ([ePOGroup]::new('Test', '123')))
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"
    $tests.Add($test) | Out-Null
}

Describe $testFile.Name {
    foreach ($test in $tests) {
        Mock Invoke-ePORequest {
            if (
                ($test.Parameters.GroupName) -and
                (-not ($test.Parameters.PassThru))
            ) {
                $File = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter ('{0}_Json.html' -f $Test.Parameters.GroupName) -File
            } elseif (
                ($test.Parameters.GroupName) -and
                ($test.Parameters.PassThru)
            ) {
                $File = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter ('{0}_Terse.html' -f $Test.Parameters.GroupName) -File
            } elseif (
                (-not ($test.Parameters.GroupName)) -and
                ($test.Parameters.PassThru)
            ) {
                $File = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter 'AllGroups_Terse.html' -File
            } else {
                $File = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter 'AllGroups_Json.html' -File
            }

            return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
        }

        Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

            if ($Test.Output.Throws) {
                It "Get-ePOGroup Throws" {
                    { $script:RequestResponse = Get-ePOGroup @parameters } | Should Throw
                }
                continue
            }

            if ($Test.Pipeline) {
                if ($Test.ePOGroupObject) {
                    It "Get-ePOGroup through pipelined ePOGroup" {
                        { $script:RequestResponse = $Test.ePOGroup | Get-ePOGroup } | Should Not Throw
                    }
                } else {
                    It "Get-ePOGroup through pipelined Name" {
                        { $script:RequestResponse = $Parameters.GroupName | Get-ePOGroup } | Should Not Throw
                    }
                }
            } else {
                It "Get-ePOGroup" {
                    { $script:RequestResponse = Get-ePOGroup @parameters } | Should Not Throw
                }
            }

            It "Output Type: $($test.Output.Type)" {
                if ($test.Output.Type -eq 'System.Void') {
                    $script:RequestResponse | Should BeNullOrEmpty
                } else {
                    $script:RequestResponse.GetType().FullName | Should Be $test.Output.Type
                }
            }
        }
    }
}