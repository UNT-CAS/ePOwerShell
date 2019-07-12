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
            Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue
            Remove-Variable -Scope 'Script' -Name 'ReturnResponse' -Force -ErrorAction SilentlyContinue

            if ($Test.ePOwerShell) {
                $SuperSecretPassword = ConvertTo-SecureString $Test.ePOwerShell.Password -AsPlainText -Force
                $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.ePOwerShell.Username, $SuperSecretPassword)

                $script:ePOwerShell = @{
                    Port = $Test.ePOwerShell.Port
                    Server = $Test.ePOwerShell.Server
                    Credentials = $Credentials
                }
            }

            Context $Test.Name {
                if ($Test.Output.Throws) {
                    It "Get-ePOConfig Throws" {
                        { $script:RequestResponse = Get-ePOConfig } | Should Throw
                    }
                    continue
                }

                It "Get-ePOConfig" {
                    { $script:ReturnResponse = Get-ePOConfig } | Should Not Throw
                }

                It "`$ePOwerShell exists" {
                    { $script:ReturnResponse } | Should Not BeNullOrEmpty
                }

                It "Has correct port" {
                    $script:ReturnResponse.Port | Should Be $Test.ePOwerShell.Port
                }

                It "Has correct server" {
                    $script:ReturnResponse.Server | Should Be $Test.ePOwerShell.Server
                }

                It "Has correct Username" {
                    $script:ReturnResponse.Credentials.Username | Should Be $Test.ePOwerShell.Username
                }

                It "Has correct Password" {
                    [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($script:ReturnResponse.Credentials.Password)) | Should Be $Test.ePOwerShell.Password
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
}