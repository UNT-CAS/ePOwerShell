[System.String]    $ProjectDirectoryName = 'ePOwerShell'
[System.String]    $FunctionType         = 'Public'
[IO.FileInfo]      $PesterFile           = [IO.FileInfo] ([System.String] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[System.String]    $FunctionName         = $PesterFile.Name.Split('.')[0]
[IO.DirectoryInfo] $ProjectRoot          = Split-Path -Parent $PesterFile.Directory

while (-not ($ProjectRoot.Name -eq $ProjectDirectoryName)) {
    $ProjectRoot = Split-Path -Parent $ProjectRoot.FullName
}

[IO.DirectoryInfo] $ExampleDirectory     = Join-Path (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -ChildPath $FunctionType -Resolve
[IO.DirectoryInfo] $ExampleDirectory     = Join-Path $ExampleDirectory.FullName -ChildPath $FunctionName -Resolve
[IO.DirectoryInfo] $Global:ReferenceDirectory   = Join-Path $ExampleDirectory.FullName -ChildPath 'References' -Resolve

$Examples = Get-ChildItem $ExampleDirectory -Filter "*.psd1" -File

$Tests = foreach ($Example in $Examples) {
    [hashtable] $Test = @{
        Name = $Example.BaseName.Split('.')[1]
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"

    foreach ($ExampleData in (Import-PowerShellDataFile -LiteralPath $Example.FullName).GetEnumerator()) {
        $Test.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"
    Write-Output $Test
}

Describe $FunctionName {
    foreach ($Global:Test in $Tests) {
        InModuleScope ePOwerShell {
            Mock Invoke-ePORequest {
                if ($Test.Parameters.ComputerName) {
                    if ($Test.Parameters.ForceWildcardHandling) {
                        $File = Get-ChildItem $ReferenceDirectory.FullName -Filter 'AllComputers.html' -File
                        return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    } else {
                        $File = Get-ChildItem $ReferenceDirectory.FullName -Filter ('{0}.html' -f $Query.searchText) -File
                        return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    }
                } elseif ($Test.Parameters.MACAddress) {
                    $Files = Get-ChildItem $ReferenceDirectory.FullName -Exclude 'AllComputers.html'
                    foreach ($File in $Files) {
                        if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOComputerProperties.NetAddress' -eq $Query.searchText) {
                            return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                        }
                    }
                } elseif ($Test.Parameters.Tag) {
                    [System.Collections.ArrayList] $Found = @()
                    $Files = Get-ChildItem $ReferenceDirectory.FullName -Exclude 'AllComputers.html'
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
                } elseif ($Test.Parameters.AgentGuid) {
                    $Files = Get-ChildItem $ReferenceDirectory.FullName -Exclude 'AllComputers.html'
                    foreach ($File in $Files) {
                        if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOLeafNode.AgentGUID' -eq $Query.searchText) {
                            return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                        }
                    }
                } elseif ($Test.Parameters.Username) {
                    $Files = Get-ChildItem $ReferenceDirectory.FullName -Exclude 'AllComputers.html'
                    foreach ($File in $Files) {
                        if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOComputerProperties.UserName' -eq $Query.searchText) {
                            return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                        }
                    }
                } elseif ($Test.Parameters.IPAddress) {
                    $Files = Get-ChildItem $ReferenceDirectory.FullName -Exclude 'AllComputers.html'
                    foreach ($File in $Files) {
                        if (((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json).'EPOComputerProperties.IPAddress' -eq $Query.searchText) {
                            return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                        }
                    }
                } else {
                    $File = Get-ChildItem $ReferenceDirectory.FullName -Filter 'AllComputers.html'
                    return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                }
            }
    
            Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue
    
            Context $Test.Name {
                [hashtable] $parameters = $Test.Parameters
    
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
                    It "Output Type: $($Test.Output.Type)" {
                        if ($Test.Output.Type -eq 'System.Void') {
                            $script:RequestResponse | Should BeNullOrEmpty
                        } else {
                            $script:RequestResponse.GetType().FullName | Should Be $Test.Output.Type
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

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
    Remove-Variable -Scope 'Global' -Name 'ReferenceDirectory' -Force -ErrorAction SilentlyContinue
}