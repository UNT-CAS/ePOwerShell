[System.String]    $ProjectDirectoryName = 'ePOwerShell'
[System.String]    $FunctionType         = 'Public'
[IO.FileInfo]      $PesterFile           = [IO.FileInfo] ([System.String] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[System.String]    $FunctionName         = $PesterFile.Name.Split('.')[0]
[IO.DirectoryInfo] $ProjectRoot          = Split-Path -Parent $PesterFile.Directory

while (-not ($ProjectRoot.Name -eq $ProjectDirectoryName)) {
    $ProjectRoot = Split-Path -Parent $ProjectRoot.FullName
}

[IO.DirectoryInfo] $ExampleDirectory          = Join-Path (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -ChildPath $FunctionType -Resolve
[IO.DirectoryInfo] $ExampleDirectory          = Join-Path $ExampleDirectory.FullName -ChildPath $FunctionName -Resolve
[IO.DirectoryInfo] $Global:ReferenceDirectory = Join-Path $ExampleDirectory.FullName -ChildPath 'References' -Resolve

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
            Mock Get-ePOComputer {
                if ($File = Get-ChildItem $ReferenceDirectory.FullName -Filter ('{0}.html' -f $Test.Parameters.Computer) -File) {
                    return ((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json)
                }

                return $Null
            }
            
            Mock Invoke-ePOQuery {
                if ($File = Get-ChildItem $ReferenceDirectory.FullName -Filter ('{0}MountPoints.html' -f $Test.Parameters.Computer) -File) {
                    return ((Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json)
                }
                
                return $Null
            }
            
            Mock Invoke-ePORequest {
                if ($File = Get-ChildItem $ReferenceDirectory.FullName -Filter ('{0}.html' -f $Query.serialNumber) -File) {
                    return (Get-Content $File.FullName | Out-String).Substring(3).Trim()
                }

                Throw "Failed to find file"
            }

            Mock Write-Warning {
                Write-Verbose $Message
            }

            Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

            Context $Test.Name {
                [hashtable] $Parameters = $Test.Parameters

                if ($Test.Output.Throws) {
                    It "Get-ePORecoveryKey Throws" {
                        { $script:RequestResponse = Get-ePORecoveryKey @Parameters } | Should Throw
                    }
                    continue
                }

                if ($Test.Pipeline) {
                    It "Get-ePORecoveryKey Does Not Throws" {
                        { $script:RequestResponse = $Parameters.Computer | Get-ePORecoveryKey } | Should Not Throw
                    }
                } else {
                    It "Get-ePORecoveryKey Does Not Throws" {
                        { $script:RequestResponse = Get-ePORecoveryKey @Parameters } | Should Not Throw
                    }
                }


                It "Output Type: $($Test.Output.Type)" {
                    if ($Test.Output.Type -eq 'System.Void') {
                        $script:RequestResponse | Should BeNullOrEmpty
                    } else {
                        $script:RequestResponse.GetType().FullName | Should Be $Test.Output.Type
                    }
                }

                foreach ($Item in $script:RequestResponse) {
                    It "Object Type: ePORecoveryKey" {
                        $Item.GetType().Fullname | Should Be 'ePORecoveryKey'
                    }
                }

                It "Has the correct count: $($Test.Output.Count)" {
                    $script:RequestResponse.Count | Should Be $Test.Output.Count
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
    Remove-Variable -Scope 'Global' -Name 'ReferenceDirectory' -Force -ErrorAction SilentlyContinue
}