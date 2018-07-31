[string]           $projectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $pesterFile = [io.fileinfo] ([string] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $projectRoot = Split-Path -Parent $pesterFile.Directory
[IO.DirectoryInfo] $projectDirectory = Join-Path -Path $projectRoot -ChildPath $projectDirectoryName -Resolve
[IO.FileInfo]      $testFile = Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Public' -ChildPath ($pesterFile.Name -replace '\.Tests\.', '.')) -Resolve
. $testFile

[System.Collections.ArrayList] $tests = @()
$examples = Get-ChildItem (Join-Path -Path $projectRoot -ChildPath 'Examples' -Resolve) -Filter "$($testFile.BaseName).*.psd1" -File

foreach ($example in $examples) {
    [hashtable] $test = @{
        Name       = $example.BaseName.Replace("$($testFile.BaseName).$verb", '').Replace('_', ' ')
        Parameters = @{}
    }
    Write-Verbose "Test: $($test | ConvertTo-Json)"

    foreach ($exampleData in (Import-PowerShellDataFile -LiteralPath $example.FullName).GetEnumerator()) {
        $test.Add($exampleData.Name, $exampleData.Value) | Out-Null
    }

    Write-Verbose "Test: $($test | ConvertTo-Json)"
    $tests.Add($test) | Out-Null
}

Describe $testFile.Name {
    foreach ($test in $tests) {
        Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue
        Remove-Variable -Scope 'Script' -Name 'ReturnResponse' -Force -ErrorAction SilentlyContinue

        if ($test.ePOwerShell) {
            $SuperSecretPassword = ConvertTo-SecureString $Test.ePOwerShell.Password -AsPlainText -Force
            $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.ePOwerShell.Username, $SuperSecretPassword)

            $script:ePOwerShell = @{
                Port = $test.ePOwerShell.Port
                Server = $Test.ePOwerShell.Server
                Credentials = $Credentials
            }
        }

        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

            if ($Test.Output.Throws) {
                It "Get-ePOwerShellServer Throws" {
                    { $script:RequestResponse = Get-ePOwerShellServer @parameters } | Should Throw
                }
                continue
            }

            It "Get-ePOwerShellServer" {
                { $script:ReturnResponse = Get-ePOwerShellServer @parameters } | Should Not Throw
            }

            It "`$ePOwerShell exists" {
                { $script:ReturnResponse } | Should Not BeNullOrEmpty
            }

            It "Has correct port" {
                $script:ReturnResponse.Port | Should Be $test.ePOwerShell.Port
            }

            It "Has correct server" {
                $script:ReturnResponse.Server | Should Be $test.ePOwerShell.Server
            }

            It "Has correct Username" {
                $script:ReturnResponse.Credentials.Username | Should Be $test.ePOwerShell.Username
            }

            It "Has correct Password" {
                [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($script:ReturnResponse.Credentials.Password)) | Should Be $test.ePOwerShell.Password
            }
        }
    }
}