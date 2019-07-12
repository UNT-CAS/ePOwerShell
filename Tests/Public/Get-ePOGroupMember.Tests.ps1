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
                $File = Get-ChildItem $ReferenceDirectory.FullName -Filter ('{0}.html' -f $Query.groupId) -File
                $GroupMembers = (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json

                if ($Test.Parameters.Recurse) {
                    $File = Get-ChildItem $ReferenceDirectory.FullName -Filter ('{0}.html' -f $Test.Subgroup) -File
                    $GroupMembers += (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                }

                return $GroupMembers
            }

            Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

            Context $Test.Name {
                [hashtable] $parameters = $Test.Parameters

                if ($Test.Output.Throws) {
                    It "Get-ePOGroupMember Throws" {
                        { $script:RequestResponse = Get-ePOGroupMember @parameters } | Should Throw
                    }
                    continue
                }

                if ($Test.Pipeline) {
                    if ($Test.ePOGroupObject) {
                        It "Get-ePOGroupMember through pipelined ePOGroup" {
                            { $script:RequestResponse = $Test.ePOGroup | Get-ePOGroupMember } | Should Not Throw
                        }
                    } else {
                        It "Get-ePOGroupMember through pipelined Name" {
                            { $script:RequestResponse = $Parameters.GroupName | Get-ePOGroupMember } | Should Not Throw
                        }
                    }
                } else {
                    It "Get-ePOGroupMember" {
                        { $script:RequestResponse = Get-ePOGroupMember @parameters } | Should Not Throw
                    }
                }

                It "Output Type: $($Test.Output.Type)" {
                    if ($Test.Output.Type -eq 'System.Void') {
                        $script:RequestResponse | Should BeNullOrEmpty
                    } else {
                        $script:RequestResponse.GetType().FullName | Should Be $Test.Output.Type
                    }
                }

                It "Should be the correct count: $($Test.Output.Count)" {
                    $script:RequestResponse.Count | Should Be $Test.Output.Count
                }

                foreach ($Item in $script:RequestResponse) {
                    It "Should be: ePOComputer" {
                        $Item.GetType().FullName | Should Be ePOComputer
                    }
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
    Remove-Variable -Scope 'Global' -Name 'ReferenceDirectory' -Force -ErrorAction SilentlyContinue
}