[string]           $projectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $pesterFile = [io.fileinfo] ([string] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $projectRoot = Split-Path -Parent $pesterFile.Directory
[IO.DirectoryInfo] $projectDirectory = Join-Path -Path $projectRoot -ChildPath $projectDirectoryName -Resolve
[IO.DirectoryInfo] $exampleDirectory = [IO.DirectoryInfo] ([String] (Resolve-Path (Get-ChildItem (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -Filter (($pesterFile.Name).Split('.')[0]) -Directory).FullName))
[IO.FileInfo]      $testFile = Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Public' -ChildPath ($pesterFile.Name -replace '\.Tests\.', '.')) -Resolve
. $testFile

. $(Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Private' -ChildPath 'Invoke-ePORequest.ps1') -Resolve)

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

    Write-Verbose "Test: $($test | ConvertTo-Json)"
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

            if ($Test.Parameters.PassThru) {
                return (Get-Content $File.FullName | Out-String).Substring(3).Trim()
            } else {
                return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
            }
        }

        Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

            if ($Test.Output.Throws) {
                It "Find-ePOwerShellGroups Throws" {
                    { $script:RequestResponse = Find-ePOwerShellGroups @parameters } | Should Throw
                }
                continue
            }

            if (
                ($Test.Pipeline) -and
                (-not ($parameters.PassThru))
            ) {
                It "Find-ePOwerShellGroups through pipeline" {
                    { $script:RequestResponse = $Parameters.GroupName | Find-ePOwerShellGroups } | Should Not Throw
                }
            } elseif (
                ($Test.Pipeline) -and
                ($parameters.PassThru)
            ) {
                It "Find-ePOwerShellGroups through pipeline" {
                    { $script:RequestResponse = $Parameters.GroupName | Find-ePOwerShellGroups -PassThru } | Should Not Throw
                }
            } else {
                It "Find-ePOwerShellGroups" {
                    { $script:RequestResponse = Find-ePOwerShellGroups @parameters } | Should Not Throw
                }
            }

            It "Output Type: $($test.Output.Type)" {
                if ($test.Output.Type -eq 'System.Void') {
                    $script:RequestResponse | Should BeNullOrEmpty
                } else {
                    $script:RequestResponse.GetType().FullName | Should Be $test.Output.Type
                }
            }

            It "Correct Count: $($test.Output.Count)" {
                $script:RequestResponse.Count | Should Be $test.Output.Count
            }
        }
    }
}