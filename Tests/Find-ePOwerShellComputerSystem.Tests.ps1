[string]           $projectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $pesterFile = [io.fileinfo] ([string] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $projectRoot = Split-Path -Parent $pesterFile.Directory
[IO.DirectoryInfo] $projectDirectory = Join-Path -Path $projectRoot -ChildPath $projectDirectoryName -Resolve
[IO.DirectoryInfo] $exampleDirectory = [IO.DirectoryInfo] ([String] (Resolve-Path (Get-ChildItem (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -Filter (($pesterFile.Name).Split('.')[0]) -Directory).FullName))
[IO.FileInfo]      $testFile = Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Public' -ChildPath ($pesterFile.Name -replace '\.Tests\.', '.')) -Resolve
. $testFile

. $(Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Private' -ChildPath 'Invoke-ePOwerShellRequest.ps1') -Resolve)

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
        Mock Invoke-ePOwerShellRequest {
            if ($test.Parameters.ComputerName) {
                if ($test.Parameters.ForceWildcardHandling) {
                    $File = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter 'AllComputers.html' -File
                    return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                } else {
                    $File = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter ('{0}.html' -f $Query.searchText) -File
                    return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                }
            } elseif ($test.Parameters.MACAddress) {
                $Files = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Exclude 'AllComputers.html'
                foreach ($File in $Files) {
                    if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOComputerProperties.NetAddress' -eq $Query.searchText) {
                        return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    }
                }
            } elseif ($test.Parameters.Tag) {
                [System.Collections.ArrayList] $Found = @()
                $Files = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Exclude 'AllComputers.html'
                foreach ($File in $Files) {
                    if ((((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOLeafNode.Tags').Split(',').Trim() -contains $Query.searchText) {
                        $Found.Add(((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json)) | Out-Null
                    }
                }

                if ($Found.Count -eq 0) {
                    Throw "Failed to find computer with this tag"
                } else {
                    return $Found
                }
            } elseif ($test.Parameters.AgentGuid) {
                $Files = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Exclude 'AllComputers.html'
                foreach ($File in $Files) {
                    if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOLeafNode.AgentGUID' -eq $Query.searchText) {
                        return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    }
                }
            } elseif ($test.Parameters.Username) {
                $Files = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Exclude 'AllComputers.html'
                foreach ($File in $Files) {
                    if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOComputerProperties.UserName' -eq $Query.searchText) {
                        return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    }
                }
            } elseif ($test.Parameters.IPAddress) {
                $Files = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Exclude 'AllComputers.html'
                foreach ($File in $Files) {
                    if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOComputerProperties.IPAddress' -eq $Query.searchText) {
                        return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    }
                }
            } else {
                $File = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter 'AllComputers.html'
                return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
            }
        }

        Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

            if ($Test.Output.Throws) {
                It "Find-ePOwerShellComputerSystem Throws" {
                    { $script:RequestResponse = Find-ePOwerShellComputerSystem @parameters } | Should Throw
                }
                continue
            }

            if ($Test.Pipeline) {
                It "Find-ePOwerShellComputerSystem through pipeline" {
                    { $script:RequestResponse = $Parameters.ComputerName | Find-ePOwerShellComputerSystem } | Should Not Throw
                }
            } else {
                It "Find-ePOwerShellComputerSystem" {
                    { $script:RequestResponse = Find-ePOwerShellComputerSystem @parameters } | Should Not Throw
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