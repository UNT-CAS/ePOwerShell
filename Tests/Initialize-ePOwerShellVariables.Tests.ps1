[string]           $projectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $pesterFile = [io.fileinfo] ([string] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $projectRoot = Split-Path -Parent $pesterFile.Directory
[IO.DirectoryInfo] $projectDirectory = Join-Path -Path $projectRoot -ChildPath $projectDirectoryName -Resolve
[IO.FileInfo]      $testFile = Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Private' -ChildPath ($pesterFile.Name -replace '\.Tests\.', '.')) -Resolve
. $testFile

[System.Collections.ArrayList] $tests = @()
$examples = Get-ChildItem (Join-Path -Path $projectRoot -ChildPath 'Examples' -Resolve) -Filter "$($testFile.BaseName).*.psd1" -File

foreach ($example in $examples) {
    [hashtable] $test = @{
        Name = $example.BaseName.Replace("$($testFile.BaseName).$verb", '').Replace('_', ' ')
        Parameters = @{}
    }
    Write-Verbose "Test: $($test | ConvertTo-Json)"

    foreach ($exampleData in (Import-PowerShellDataFile -LiteralPath $example.FullName).GetEnumerator()) {
        if (
            ($exampleData.Name -eq 'Port') -or
            ($exampleData.Name -eq 'Server')
        ) {
            $test.Parameters.Add($exampleData.Name, $exampleData.Value) | Out-Null
        } else {
            $test.Add($exampleData.Name, $exampleData.Value) | Out-Null
        }
    }

    $SuperSecretPassword = ConvertTo-SecureString $test.Password -AsPlainText -Force
    $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.Username, $SuperSecretPassword)

    $test.Parameters.Add('Credentials', $Credentials) | Out-Null

    Write-Verbose "Test: $($test | ConvertTo-Json)"
    $tests.Add($test) | Out-Null
}

Describe $testFile.Name {
    foreach ($test in $tests) {
        Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue

        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

            It "Initialize-ePOwerShellVariables" {
                { Initialize-ePOwerShellVariables @parameters } | Should Not Throw
            }

            It "`$ePOwerShell exists" {
                { $script:ePOwerShell } | Should Not BeNullOrEmpty
            }
        }
    }
}