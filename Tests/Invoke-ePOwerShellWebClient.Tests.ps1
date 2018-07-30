[string]           $projectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $pesterFile = [io.fileinfo] ([string] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $projectRoot = Split-Path -Parent $pesterFile.Directory
[IO.DirectoryInfo] $projectDirectory = Join-Path -Path $projectRoot -ChildPath $projectDirectoryName -Resolve
[IO.FileInfo]      $testFile = Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Private' -ChildPath ($pesterFile.Name -replace '\.Tests\.', '.')) -Resolve
. $testFile

. $(Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Private' -ChildPath 'Invoke-ePOwerShellWebClient.ps1') -Resolve)

[System.Collections.ArrayList] $tests = @()
$examples = Get-ChildItem (Join-Path -Path $projectRoot -ChildPath 'Examples' -Resolve) -Filter "$($testFile.BaseName).*.psd1" -File

foreach ($example in $examples) {
    [hashtable] $test = @{
        Name = $example.BaseName.Replace("$($testFile.BaseName).$verb", '').Replace('_', ' ')
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
        Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue
        # Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue

        if (($test.ePOwerShell) -and (-not $script:ePOwerShell)) {
            $script:ePOwerShell = $test.ePOwerShell
            $SuperSecretPassword = ConvertTo-SecureString $ePOwerShell.Password -AsPlainText -Force
            $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($script:ePOwerShell.Username, $SuperSecretPassword)
    
            $script:ePOwerShell.Add('Credentials', $Credentials)
        }


        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

            if ($Test.Output.Throws) {
                It "Invoke-ePOwerShellWebClient Throws" {
                    { $script:RequestResponse = Invoke-ePOwerShellWebClient @parameters } | Should Throw
                }
                continue
            }

            It "Invoke-ePOwerShellWebClient" {
                { $script:RequestResponse = Invoke-ePOwerShellWebClient @parameters } | Should Not Throw
            }

            It "Output Type: $($test.Output.Type)" {
                if ($test.Output.Type -eq 'System.Void') {
                    $script:RequestResponse | Should BeNullOrEmpty
                } else {
                    $script:RequestResponse.GetType().FullName | Should Be $test.Output.Type
                }
            }
        }
    }
}