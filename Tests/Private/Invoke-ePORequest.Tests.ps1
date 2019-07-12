[System.String]    $ProjectDirectoryName = 'ePOwerShell'
[System.String]    $FunctionType         = 'Private'
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
    [hashtable] $test = @{
        Name = $Example.BaseName.Replace("$($testFile.BaseName).$verb", '').Replace('_', ' ')
    }
    Write-Verbose "Test: $($test | ConvertTo-Json)"

    foreach ($ExampleData in (Import-PowerShellDataFile -LiteralPath $Example.FullName).GetEnumerator()) {
        $test.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
    }

    if ($test.Username -and $test.Password) {
        $SuperSecretPassword = ConvertTo-SecureString $test.Password -AsPlainText -Force
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.Username, $SuperSecretPassword)

        $test.ePOwerShell.Add('Credentials', $Credentials) | Out-Null
    }

    Write-Output $Test
}

Describe $FunctionName {
    foreach ($Global:Test in $Tests) {
        InModuleScope ePOwerShell {
            Mock Invoke-WebRequest {
                if ($Test.BreakIWR) {
                    Throw 'Breaking Invoke-WebRequest'
                }

                return @{
                    Content = (Get-Content (Join-Path -Path $ReferenceDirectory.FullName -ChildPath ('{0}.html' -f $Test.Parameters.Name) -Resolve) | Out-String)
                }
            }

            Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue
            Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue

            if ($Test.ePOwerShell) {
                $script:ePOwerShell = $Test.ePOwerShell
            }

            Context $Test.Name {
                [Hashtable] $Parameters = $Test.Parameters

                if ($Test.Output.Throws) {
                    It "Invoke-ePORequest Throws" {
                        { $script:RequestResponse = Invoke-ePORequest @parameters } | Should Throw
                    }
                    continue
                }

                It "Invoke-ePORequest" {
                    { $Script:RequestResponse = Invoke-ePORequest @Parameters } | Should Not Throw
                }

                It "Output Type: $($test.Output.Type)" {
                    if ($test.Output.Type -eq 'System.Void') {
                        $Script:RequestResponse | Should BeNullOrEmpty
                    } else {
                        $Script:RequestResponse.GetType().FullName | Should Be $test.Output.Type
                    }
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
}