[string]           $projectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $pesterFile = [io.fileinfo] ([string] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $projectRoot = Split-Path -Parent $pesterFile.Directory
[IO.DirectoryInfo] $projectDirectory = Join-Path -Path $projectRoot -ChildPath $projectDirectoryName -Resolve
[IO.DirectoryInfo] $exampleDirectory = [IO.DirectoryInfo] ([String] (Resolve-Path (Get-ChildItem (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -Filter (($pesterFile.Name).Split('.')[0]) -Directory).FullName))
[IO.FileInfo]      $testFile = Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Public' -ChildPath ($pesterFile.Name -replace '\.Tests\.', '.')) -Resolve
. $testFile

. $(Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Private' -ChildPath 'Initialize-ePOConfig.ps1') -Resolve)

[System.Collections.ArrayList] $tests = @()
$examples = Get-ChildItem $exampleDirectory -Filter "$($testFile.BaseName).*.psd1" -File

foreach ($example in $examples) {
    [hashtable] $test = @{
        Name       = $example.BaseName.Replace("$($testFile.BaseName).$verb", '').Replace('_', ' ')
    }
    Write-Verbose "Test: $($test | ConvertTo-Json)"

    foreach ($exampleData in (Import-PowerShellDataFile -LiteralPath $example.FullName).GetEnumerator()) {
        $test.Add($exampleData.Name, $exampleData.Value) | Out-Null
    }

    if ($Test.UpdatingCredentials) {
        $SuperSecretPassword = ConvertTo-SecureString $test.Credentials.Password -AsPlainText -Force
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.Credentials.Username, $SuperSecretPassword)
        if (-not ($test.Parameters)) {
            $Test.Parameters = @{}
        }
    
        [void]$test.Parameters.Add('Credentials', $Credentials)
    }

    Write-Verbose "Test: $($test | ConvertTo-Json)"
    $tests.Add($test) | Out-Null
}

Describe $testFile.Name {
    foreach ($test in $tests) {
        Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue
        Remove-Variable -Scope 'Script' -Name 'ReturnResponse' -Force -ErrorAction SilentlyContinue

        if ($test.ePOwerShell) {
            $Script:ePOwerShell = @{
                Server   = $test.ePOwerShell.Server
                Port     = $test.ePOwerShell.Port
                Credentials = (New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.ePOwerShell.Username, (ConvertTo-SecureString $test.ePOwerShell.Password -AsPlainText -Force)))
            }
        }

        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

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