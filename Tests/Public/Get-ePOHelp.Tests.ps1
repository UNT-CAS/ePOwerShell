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
            Mock Invoke-ePORequest {
                $File = Get-ChildItem $ReferenceDirectory -Filter $Test.File -File
                $Content = (Get-Content $File.FullName | Out-String).SubString(3)
                return $Content | ConvertFrom-Json
            }

            Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

            Context $Test.Name {
                [hashtable] $parameters = $Test.Parameters

                if ($Test.Output.Throws) {
                    It "Get-ePOHelp Throws" {
                        { $script:RequestResponse = Get-ePOHelp @parameters } | Should Throw
                    }

                    continue
                }

                if ($Test.Pipeline) {
                    $TestHelp = [ePOHelp]::new()
                    $TestHelp.CommandName = $Parameters.Command
                    It "Get-ePOHelp With Pipeline" {
                        { $script:RequestResponse = ($TestHelp | Get-ePOHelp) } | Should Not Throw
                    }
                } else {
                    It "Get-ePOHelp" {
                        { $script:RequestResponse = Get-ePOHelp @parameters } | Should Not Throw
                    }
                }


                It "Output Type: $($Test.Output.Type)" {
                    $script:RequestResponse.GetType().FullName | Should Be $Test.Output.Type
                }

                if ($Test.Output.Type -eq 'System.Object[]') {
                    It "Contains ePOHelp objects" {
                        foreach ($HelpItem in $RequestResponse) {
                            $HelpItem.GetType().FullName | Should Be 'ePOHelp'
                        }
                    }
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
    Remove-Variable -Scope 'Global' -Name 'ReferenceDirectory' -Force -ErrorAction SilentlyContinue
}