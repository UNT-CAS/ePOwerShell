[string]           $projectDirectoryName = 'ePOwerShell'
[IO.FileInfo]      $pesterFile = [io.fileinfo] ([string] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[IO.DirectoryInfo] $projectRoot = Split-Path -Parent $pesterFile.Directory
[IO.DirectoryInfo] $projectDirectory = Join-Path -Path $projectRoot -ChildPath $projectDirectoryName -Resolve
[IO.DirectoryInfo] $exampleDirectory = [IO.DirectoryInfo] ([String] (Resolve-Path (Get-ChildItem (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -Filter (($pesterFile.Name).Split('.')[0]) -Directory).FullName))
[IO.FileInfo]      $testFile = Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Public' -ChildPath ($pesterFile.Name -replace '\.Tests\.', '.')) -Resolve
. $testFile

. $(Join-Path -Path $projectDirectory -ChildPath (Join-Path -Path 'Private' -ChildPath 'Invoke-ePORequest.ps1') -Resolve)

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

Write-Host "Example Directory: $exampleDirectory"

Describe $testFile.Name {
    foreach ($test in $tests) {
        Mock Invoke-ePORequest {
            if (-not ($ComputerFile = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter ('{0}.html' -f $Query.names))) {
                Throw "Error 1: Invalid computername"
            }
            if (-not ($TagFile = Get-ChildItem (Join-Path -Path $exampleDirectory -ChildPath 'References' -Resolve) -Filter ('{0}.html' -f $Query.tagName))) {
                Throw "Error 1: Invalid tag"
            }

            $Computer = (Get-Content $ComputerFile.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
            $Tag = (Get-Content $TagFile.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json

            if ($Test.Unknown) {
                return 4
            } elseif ($Computer.'EPOLeafNode.Tags'.Split(',').Trim() | ? { $_ -eq $Tag.tagName }) {
                return 0
            } else {
                return 1
            }
        }

        Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

        Context $test.Name {
            [hashtable] $parameters = $test.Parameters

            if ($Test.Output.Throws) {
                It "Set-ePOwerShellTag Throws" {
                    { $script:RequestResponse = Set-ePOwerShellTag @parameters } | Should Throw
                }
                continue
            }

            It "Set-ePOwerShellTag" {
                { $script:RequestResponse = Set-ePOwerShellTag @parameters } | Should Not Throw
            }
            
            It "Output Type: $($test.Output.Type)" {
                $script:RequestResponse | Should BeNullOrEmpty
            }
        }
    }
}