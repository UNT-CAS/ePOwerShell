[string]           $projectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $pesterFile = [io.fileinfo] ([string] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $projectRoot = Split-Path -Parent $pesterFile.Directory
[IO.DirectoryInfo] $projectDirectory = Join-Path -Path $projectRoot -ChildPath $projectDirectoryName -Resolve
[IO.DirectoryInfo] $exampleDirectory = [IO.DirectoryInfo] ([String] (Resolve-Path (Get-ChildItem (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -Filter (($pesterFile.Name).Split('.')[0]) -Directory).FullName))
[IO.FileInfo]      $testFile = Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Public' -ChildPath ($pesterFile.Name -replace '\.Tests\.', '.')) -Resolve
. $testFile

. $(Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Private' -ChildPath 'Invoke-ePOwerShellRequest.ps1') -Resolve)
. $(Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Public' -ChildPath 'Find-ePOwerShellComputerSystem.ps1') -Resolve)

[System.Collections.ArrayList] $tests = @()
$examples = Get-ChildItem $exampleDirectory -Filter "$($testFile.BaseName).*.psd1" -File

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
        Mock Invoke-ePOwerShellRequest {
            $File = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter ('{0}.html' -f $test.ResultsFile)
            return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
        }
        
        Mock Find-ePOwerShellComputerSystem {
            if ($File = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter ('{0}.html' -f $ComputerName)) {
                return (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
            }
            return $Null
        }

        Mock Write-Warning {
            Write-Debug $Message
        }

        Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

            if ($Test.Output.Throws) {
                if ($Test.Pipeline) {
                    It "Invoke-ePOwerShellWakeUpAgent Throws through pipeline" {
                        { $script:RequestResponse = $Parameters.ComputerName | Invoke-ePOwerShellWakeUpAgent } | Should Throw
                    }
                } else {
                    It "Invoke-ePOwerShellWakeUpAgent Throws" {
                        { $script:RequestResponse = Invoke-ePOwerShellWakeUpAgent @parameters } | Should Throw
                    }
                }
                continue
            }

            if ($Test.Pipeline) {
                It "Invoke-ePOwerShellWakeUpAgent through pipeline" {
                    { $script:RequestResponse = $Parameters.ComputerName | Invoke-ePOwerShellWakeUpAgent } | Should Not Throw
                }
            } else {
                It "Invoke-ePOwerShellWakeUpAgent" {
                    { $script:RequestResponse = Invoke-ePOwerShellWakeUpAgent @parameters } | Should Not Throw
                }
            }
            
            It "Output Type: Null" {
                $script:RequestResponse | Should BeNullOrEmpty
            }
        }
    }
}