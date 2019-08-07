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
                if (-not ($ResultsFile = Get-ChildItem $ReferenceDirectory.FullName -Filter ('{0}.html' -f $Query.ids))) {
                    Throw "Error 1: Invalid computername"
                }

                $Results = (Get-Content $ResultsFile.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                Write-Output $Results
            }

            Mock Get-ePOComputer {
                if (-not ($ComputerFile = Get-ChildItem $ReferenceDirectory.FullName -Filter ('{0}.html' -f $Computer))) {
                    Throw "Error 1: Invalid computername"
                }

                $Computer = ConvertTo-ePOComputer ((Get-Content $ComputerFile.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json)
                Write-Output $Computer
            }

            Mock Write-Warning {
                Write-Debug $Message
            }

            Mock Write-Error {
                Throw $Message
            }

            Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

            Context $Test.Name {
                [hashtable] $parameters = $Test.Parameters

                if ($Test.Output.Throws) {
                    It "Remove-ePOComputer Throws" {
                        { $script:RequestResponse = Remove-ePOComputer @parameters -Confirm:$False} | Should Throw
                    }
                    continue
                }

                It "Remove-ePOComputer" {
                    { $script:RequestResponse = Remove-ePOComputer @parameters -Confirm:$False } | Should Not Throw
                }
                
                It "Output Type: $($Test.Output.Type)" {
                    $script:RequestResponse | Should BeNullOrEmpty
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
    Remove-Variable -Scope 'Global' -Name 'ReferenceDirectory' -Force -ErrorAction SilentlyContinue
}