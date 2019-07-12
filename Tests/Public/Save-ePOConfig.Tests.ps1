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

$Examples = Get-ChildItem $ExampleDirectory -Filter "*.psd1" -File

$Tests = foreach ($Example in $Examples) {
    [hashtable] $Test = @{
        Name = $Example.BaseName.Split('.')[1]
        Parameters = @{}
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"

    foreach ($exampleData in (Import-PowerShellDataFile -LiteralPath $example.FullName).GetEnumerator()) {
        if (
            ($exampleData.Name -eq 'Port') -or
            ($exampleData.Name -eq 'Server')
        ) {
            $Test.Parameters.Add($exampleData.Name, $exampleData.Value) | Out-Null
        } else {
            $Test.Add($exampleData.Name, $exampleData.Value) | Out-Null
        }
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"
    Write-Output $Test
}


Describe $FunctionName {
    foreach ($Global:Test in $Tests) {
        InModuleScope ePOwerShell {
            Mock Write-Information {
                Throw $_
            }
            
            Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue
            
            if ($Test.ePOwerShell) {
                $SuperSecretPassword = (ConvertTo-SecureString $Test.ePOwerShell.Password -AsPlainText -Force)
                $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.ePOwerShell.Username, $SuperSecretPassword)

                $script:ePOwerShell = @{
                    Server   = $Test.ePOwerShell.Server
                    Port     = $Test.ePOwerShell.Port
                    Credentials = $Credentials
                    AllowSelfSignedCerts = $Test.ePOwerShell.AllowSelfSignedCerts
                }
            }

            Context $Test.Name {
                [hashtable] $parameters = $Test.Parameters

                if ($Test.Output.Throws) {
                    if ($Test.BreakJson) {
                        Mock ConvertFrom-Json {
                            Throw "This should break it"
                        }
                    }

                    It "Save-ePOConfig Throws" {
                        { Save-ePOConfig @parameters -WhatIf } | Should Throw
                    }
                    continue
                }

                It "Save-ePOConfig" {
                    { Save-ePOConfig @parameters -WhatIf } | Should Not Throw
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
    Remove-Variable -Scope 'Global' -Name 'ReferenceDirectory' -Force -ErrorAction SilentlyContinue
}