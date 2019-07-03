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
            $env:ePOwerShell = $Null
            if ($Test.ePOwerShell) {
                if ($Test.ePOwerShellFilePath) {
                    $FilePath = $Test.ePOwerShellFilePath -f ($Test.ePOwerShellFilePath_f | Invoke-Expression)

                    @{
                        Server      = $Test.ePOwerShell.Server
                        Port        = $Test.ePOwerShell.Port
                        Username    = $Test.ePOwerShell.Username
                        Password    = (ConvertTo-SecureString $Test.ePOwerShell.Password -AsPlainText -Force | ConvertFrom-SecureString)
                    } | ConvertTo-Json | Out-File $FilePath -Force

                    $env:ePOwerShell = $FilePath
                } else {
                    $env:ePOwerShell = @{
                        Server   = $Test.ePOwerShell.Server
                        Port     = $Test.ePOwerShell.Port
                        Username = $Test.ePOwerShell.Username
                        Password = (ConvertTo-SecureString $Test.ePOwerShell.Password -AsPlainText -Force | ConvertFrom-SecureString)
                    } | ConvertTo-Json -Compress
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

                    It "Set-ePOConfig Throws" {
                        { Set-ePOConfig @parameters } | Should Throw
                    }
                    continue
                }

                It "Set-ePOConfig" {
                    { Set-ePOConfig @parameters } | Should Not Throw
                }

                if ($Test.ePOwerShellFilePath) {
                    $FilePath = $Test.ePOwerShellFilePath -f ($Test.ePOwerShellFilePath_f | iex)
                    Remove-Item $FilePath -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
    Remove-Variable -Scope 'Global' -Name 'ReferenceDirectory' -Force -ErrorAction SilentlyContinue
}