[string]           $projectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $pesterFile = [io.fileinfo] ([string] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $projectRoot = Split-Path -Parent $pesterFile.Directory
[IO.DirectoryInfo] $projectDirectory = Join-Path -Path $projectRoot -ChildPath $projectDirectoryName -Resolve
[IO.DirectoryInfo] $exampleDirectory = [IO.DirectoryInfo] ([String] (Resolve-Path (Get-ChildItem (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -Filter (($pesterFile.Name).Split('.')[0]) -Directory).FullName))
[IO.FileInfo]      $testFile = Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Public' -ChildPath ($pesterFile.Name -replace '\.Tests\.', '.')) -Resolve
. $testFile

. $(Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Private' -ChildPath 'Initialize-ePOwerShellVariables.ps1') -Resolve)

[System.Collections.ArrayList] $tests = @()
$examples = Get-ChildItem $exampleDirectory -Filter "$($testFile.BaseName).*.psd1" -File

foreach ($example in $examples) {
    [hashtable] $test = @{
        Name       = $example.BaseName.Replace("$($testFile.BaseName).$verb", '').Replace('_', ' ')
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

    if ($test.Username -and $test.Password) {
        $SuperSecretPassword = ConvertTo-SecureString $test.Password -AsPlainText -Force
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.Username, $SuperSecretPassword)
    
        $test.Parameters.Add('Credentials', $Credentials) | Out-Null
    }

    Write-Verbose "Test: $($test | ConvertTo-Json)"
    $tests.Add($test) | Out-Null
}

Describe $testFile.Name {
    foreach ($test in $tests) {
        $env:ePOwerShell = $Null
        if ($test.ePOwerShell) {
            if ($test.ePOwerShellFilePath) {
                $FilePath = $test.ePOwerShellFilePath -f ($test.ePOwerShellFilePath_f | iex)

                @{
                    Server      = $test.ePOwerShell.Server
                    Port        = $test.ePOwerShell.Port
                    Username    = $test.ePOwerShell.Username
                    Password    = (ConvertTo-SecureString $test.ePOwerShell.Password -AsPlainText -Force | ConvertFrom-SecureString)
                } | ConvertTo-Json | Out-File $FilePath -Force

                $env:ePOwerShell = $FilePath
            } else {
                $env:ePOwerShell = @{
                    Server   = $test.ePOwerShell.Server
                    Port     = $test.ePOwerShell.Port
                    Username = $test.ePOwerShell.Username
                    Password = (ConvertTo-SecureString $test.ePOwerShell.Password -AsPlainText -Force | ConvertFrom-SecureString)
                } | ConvertTo-Json -Compress
            }
        }

        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

            if ($Test.Output.Throws) {
                if ($Test.BreakJson) {
                    Mock ConvertFrom-Json {
                        Throw "This should break it"
                    }
                }

                It "Set-ePOwerShellServer Throws" {
                    { Set-ePOwerShellServer @parameters } | Should Throw
                }
                continue
            }

            It "Set-ePOwerShellServer" {
                { Set-ePOwerShellServer @parameters } | Should Not Throw
            }

            if ($test.ePOwerShellFilePath) {
                $FilePath = $test.ePOwerShellFilePath -f ($test.ePOwerShellFilePath_f | iex)
                Remove-Item $FilePath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}