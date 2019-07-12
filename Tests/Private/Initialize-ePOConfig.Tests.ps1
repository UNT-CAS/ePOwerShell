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

$Examples = Get-ChildItem $ExampleDirectory -Filter "*.psd1" -File

$Tests = foreach ($Example in $Examples) {
    [Hashtable] $Test = @{
        Name = $Example.BaseName.Replace("$($TestFile.BaseName).$Verb", '').Replace('_', ' ')
        Parameters = @{}
    }
    Write-Verbose "Test: $($Test | ConvertTo-Json)"

    foreach ($ExampleData in (Import-PowerShellDataFile -LiteralPath $Example.FullName).GetEnumerator()) {
        if (
            ($ExampleData.Name -eq 'Port') -or
            ($ExampleData.Name -eq 'Server')
        ) {
            $Test.Parameters.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
        } else {
            $Test.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
        }
    }

    $SuperSecretPassword = ConvertTo-SecureString $Test.Password -AsPlainText -Force
    $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.Username, $SuperSecretPassword)

    $Test.Parameters.Add('Credentials', $Credentials) | Out-Null

    Write-Verbose "Test: $($Test | ConvertTo-Json)"
    $Test
}

Describe $FunctionName {
    foreach ($Global:Test in $Tests) {
        InModuleScope ePOwerShell {
            Mock Get-ePOHelp {
                if ($Test.CoreHelpFail) {
                    Throw 'Failing Core.help'
                }
            }

            Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue

            Context $Test.Name {
                [Hashtable] $Parameters = $Test.Parameters

                if ($Test.Output.Throws) {
                    It "Initialize-ePOConfig" {
                        { Initialize-ePOConfig @Parameters } | Should Throw
                    }

                    continue
                }

                It "Initialize-ePOConfig" {
                    { Initialize-ePOConfig @Parameters } | Should Not Throw
                }

                It "`$ePOwerShell exists" {
                    { $script:ePOwerShell } | Should Not BeNullOrEmpty
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
}