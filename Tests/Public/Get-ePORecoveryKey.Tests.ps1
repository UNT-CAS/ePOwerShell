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
$Examples = Get-ChildItem $ExampleDirectory -Filter "$($TestFile.BaseName).*.psd1" -File

foreach ($Example in $Examples) {
    [hashtable] $Test = @{
        Name = $Example.BaseName.Replace("$($TestFile.BaseName).$verb", '').Replace('_', ' ')
    }
    Write-Verbose "Test: $($Test | ConvertTo-Json)"

    foreach ($ExampleData in (Import-PowerShellDataFile -LiteralPath $Example.FullName).GetEnumerator()) {
        $Test.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"
    $Tests.Add($Test) | Out-Null
}



Describe $TestFile.Name {
    foreach ($Test in $Tests) {
        Mock Find-ePOwerShellComputerSystem {
            if ($Test.FailsToFindComputer) {
                Throw "Failed to find computer"
            }

            $File = Get-ChildItem $ReferenceDirectory -Filter ('{0}.html' -f $ComputerName) -File
            return (Get-Content $File.FullName | Out-String).Substring(3).Trim()  | ConvertFrom-Json
        }

        Mock Invoke-ePORequest {
            if ($Query.epoLeafNodeId) {
                $File = Get-ChildItem $ReferenceDirectory -Filter ('{0}.html' -f $Query.epoLeafNodeId) -File
            } else {
                $File = Get-ChildItem $ReferenceDirectory -Filter ('{0}.html' -f $Query.serialNumber) -File
            }

            if ($File) {
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
                    { $script:RequestResponse = $Parameters.ComputerName | Get-ePORecoveryKey } | Should Not Throw
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
        }
    }
}