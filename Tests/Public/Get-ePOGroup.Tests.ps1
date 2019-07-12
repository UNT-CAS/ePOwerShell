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
                if ($Test.Parameters.GroupName) {
                    $File = Get-ChildItem $ReferenceDirectory.FullName -Filter ('{0}.html' -f $Test.Parameters.GroupName) -File
                } else {
                    $File = Get-ChildItem $ReferenceDirectory.FullName -Filter 'AllGroups.html' -File
                }

                return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
            }

            Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

            Context $Test.Name {
                [hashtable] $parameters = $Test.Parameters

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

                It "Output Type: $($Test.Output.Type)" {
                    if ($Test.Output.Type -eq 'System.Void') {
                        $script:RequestResponse | Should BeNullOrEmpty
                    } else {
                        $script:RequestResponse.GetType().FullName | Should Be $Test.Output.Type
                    }
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
    Remove-Variable -Scope 'Global' -Name 'ReferenceDirectory' -Force -ErrorAction SilentlyContinue
}