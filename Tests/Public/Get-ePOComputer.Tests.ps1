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

[System.Collections.ArrayList] $Tests = @()
$Examples = Get-ChildItem $ExampleDirectory -Filter "$($testFile.BaseName).*.psd1" -File

foreach ($Example in $Examples) {
    [hashtable] $test = @{
        Name = $Example.BaseName.Replace("$($testFile.BaseName).$verb", '')
    }
    Write-Verbose "Test: $($test | ConvertTo-Json)"

    foreach ($ExampleData in (Import-PowerShellDataFile -LiteralPath $Example.FullName).GetEnumerator()) {
        $test.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
    }

    if ($Test.UseePOComputer) {
        $Test.Add('ePOComputer', (ConvertTo-ePOComputer ((Get-Content (Join-Path $ReferenceDirectory 'Computer1.html' -Resolve) | Out-String).SubString(3) | ConvertFrom-Json)))
    }

    Write-Verbose "Test: $($test | ConvertTo-Json)"
    $Tests.Add($test) | Out-Null
}

Describe $testFile.Name {
    foreach ($test in $Tests) {
        Mock Invoke-ePORequest {
            if ($test.Parameters.ComputerName) {
                if ($test.Parameters.ForceWildcardHandling) {
                    $File = Get-ChildItem (Join-Path -Path $ExampleDirectory -ChildPath 'References' -Resolve) -Filter 'AllComputers.html' -File
                    return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                } else {
                    $File = Get-ChildItem (Join-Path -Path $ExampleDirectory -ChildPath 'References' -Resolve) -Filter ('{0}.html' -f $Query.searchText) -File
                    return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                }
            } elseif ($test.Parameters.MACAddress) {
                $Files = Get-ChildItem (Join-Path -Path $ExampleDirectory -ChildPath 'References' -Resolve) -Exclude 'AllComputers.html'
                foreach ($File in $Files) {
                    if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOComputerProperties.NetAddress' -eq $Query.searchText) {
                        return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    }
                }
            } elseif ($test.Parameters.Tag) {
                [System.Collections.ArrayList] $Found = @()
                $Files = Get-ChildItem (Join-Path -Path $ExampleDirectory -ChildPath 'References' -Resolve) -Exclude 'AllComputers.html'
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
                $Files = Get-ChildItem (Join-Path -Path $ExampleDirectory -ChildPath 'References' -Resolve) -Exclude 'AllComputers.html'
                foreach ($File in $Files) {
                    if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOLeafNode.AgentGUID' -eq $Query.searchText) {
                        return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    }
                }
            } elseif ($test.Parameters.Username) {
                $Files = Get-ChildItem (Join-Path -Path $ExampleDirectory -ChildPath 'References' -Resolve) -Exclude 'AllComputers.html'
                foreach ($File in $Files) {
                    if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOComputerProperties.UserName' -eq $Query.searchText) {
                        return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    }
                }
            } elseif ($test.Parameters.IPAddress) {
                $Files = Get-ChildItem (Join-Path -Path $ExampleDirectory -ChildPath 'References' -Resolve) -Exclude 'AllComputers.html'
                foreach ($File in $Files) {
                    if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOComputerProperties.IPAddress' -eq $Query.searchText) {
                        return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    }
                }
            } else {
                $File = Get-ChildItem (Join-Path -Path $ExampleDirectory -ChildPath 'References' -Resolve) -Filter 'AllComputers.html'
                return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
            }
        }

        Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

            if ($Test.Pipeline) {
                if ($Test.UseePOComputer) {
                    It "Get-ePOComputer through pipeline" {
                        { $script:RequestResponse = $Test.ePOComputer | Get-ePOComputer } | Should Not Throw
                    }
                } else {
                    It "Get-ePOComputer through pipeline" {
                        { $script:RequestResponse = $Parameters.ComputerName | Get-ePOComputer } | Should Not Throw
                    }
                }
            } else {
                It "Get-ePOComputer" {
                    { $script:RequestResponse = Get-ePOComputer @parameters } | Should Not Throw
                }
            }

            if ($Test.Output.Throws) {
                It "Output Type: Should not return" {
                    $script:RequestResponse | Should BeNullOrEmpty
                }
            } else {
                It "Output Type: $($test.Output.Type)" {
                    if ($test.Output.Type -eq 'System.Void') {
                        $script:RequestResponse | Should BeNullOrEmpty
                    } else {
                        $script:RequestResponse.GetType().FullName | Should Be $test.Output.Type
                    }
                }

                It "Computer Type: ePOComputer" {
                    foreach ($Computer in $script:RequestResponse) {
                        $Computer.GetType().Fullname | Should Be 'ePOComputer'
                    }
                }
            }

        }
    }
}