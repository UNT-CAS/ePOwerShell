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
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"

    foreach ($exampleData in (Import-PowerShellDataFile -LiteralPath $example.FullName).GetEnumerator()) {
        $Test.Add($exampleData.Name, $exampleData.Value) | Out-Null
    }

    if ($Test.Username -and $Test.Password) {
        $SuperSecretPassword = ConvertTo-SecureString $Test.Password -AsPlainText -Force
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.Username, $SuperSecretPassword)
    
        $Test.Parameters.Add('Credentials', $Credentials) | Out-Null
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"
    Write-Output $Test
}

Describe $FunctionName {
    foreach ($Global:Test in $Tests) {
        InModuleScope ePOwerShell {
            Mock Get-ePOHelp {}

            Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue
            Remove-Variable -Scope 'Script' -Name 'ReturnResponse' -Force -ErrorAction SilentlyContinue

            if ($Test.ePOwerShell) {
                $Script:ePOwerShell = @{
                    Server   = $Test.ePOwerShell.Server
                    Port     = $Test.ePOwerShell.Port
                    Credentials = (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.ePOwerShell.Username, (ConvertTo-SecureString $Test.ePOwerShell.Password -AsPlainText -Force)))
                }
            }

            Context $Test.Name {
                [hashtable] $parameters = $Test.Parameters

                if ($Test.Output.Throws) {
                    It "Update-ePOwerShellServer Throws" {
                        { Update-ePOwerShellServer @parameters } | Should Throw
                    }
                    continue
                }

                It "Update-ePOwerShellServer" {
                    { $script:ReturnResponse = Update-ePOwerShellServer @parameters } | Should Not Throw
                }

                It "Does not return" {
                    $script:ReturnResponse | Should BeNullOrEmpty
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
}