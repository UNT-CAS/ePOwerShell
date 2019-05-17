[System.String]    $ProjectDirectoryName = 'ePOwerShell'
[System.String]    $FunctionType         = 'Public'
[IO.FileInfo]      $PesterFile           = [IO.FileInfo] ([System.String] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[System.String]    $FunctionName         = $PesterFile.Name.Split('.')[0]
[IO.DirectoryInfo] $ProjectRoot          = Split-Path -Parent $PesterFile.Directory

While (-not ($ProjectRoot.Name -eq $ProjectDirectoryName)) {
    $ProjectRoot = Split-Path -Parent $ProjectRoot.FullName
}

[IO.DirectoryInfo] $ProjectDirectory     = Join-Path -Path $ProjectRoot -ChildPath $ProjectDirectoryName -Resolve
[IO.DirectoryInfo] $PublicDirectory      = Join-Path -Path $ProjectDirectory -ChildPath 'Public' -Resolve 
[IO.DirectoryInfo] $PrivateDirectory     = Join-Path -Path $ProjectDirectory -ChildPath 'Private' -Resolve 
[IO.DirectoryInfo] $ClassesDirectory     = Join-Path -Path $ProjectDirectory -ChildPath 'Classes' -Resolve 
[IO.DirectoryInfo] $ExampleDirectory     = Join-Path (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -ChildPath $FunctionType -Resolve
[IO.DirectoryInfo] $ExampleDirectory     = Join-Path $ExampleDirectory.FullName -ChildPath $FunctionName -Resolve
[IO.DirectoryInfo] $ReferenceDirectory   = Join-Path $ExampleDirectory.FullName -ChildPath 'References' -Resolve
if ($FunctionType -eq 'Private') {
    [IO.FileInfo]  $TestFile             = Join-Path -Path $PrivateDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.', '.') -Resolve
} else {
    [IO.FileInfo]  $TestFile             = Join-Path -Path $PublicDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.', '.') -Resolve
}

. $TestFile
Get-ChildItem -Path $PublicDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }
Get-ChildItem -Path $PrivateDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }
Get-ChildItem -Path $ClassesDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }



[System.Collections.ArrayList] $Tests = @()
$Examples = Get-ChildItem $ExampleDirectory -Filter "$($TestFile.BaseName).*.psd1" -File

foreach ($Example in $Examples) {
    [hashtable] $Test = @{
        Name = $Example.BaseName.Replace("$($TestFile.BaseName).$verb", '').Replace('_', ' ')
    }
    Write-Verbose "Test: $($Test | ConvertTo-Json)"

    foreach ($ExampleData in (Import-PowerShellDataFile -LiteralPath $Example.FullName).GetEnumerator()) {
        $Test.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"
    $Tests.Add($Test) | Out-Null
}



Describe $TestFile.Name {
    foreach ($Test in $Tests) {
        Mock Invoke-ePORequest {
            $File = Get-ChildItem $ReferenceDirectory -Filter $Test.File -File
            $Content = (Get-Content $File.FullName | Out-String).SubString(3)
            return $Content | ConvertFrom-Json
        }

        Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

        Context $Test.Name {
            [hashtable] $parameters = $Test.Parameters

            if ($Test.Output.Throws) {
                It "Get-ePOHelp Throws" {
                    { $script:RequestResponse = Get-ePOHelp @parameters } | Should Throw
                }

                continue
            }

            if ($Test.Pipeline) {
                $TestHelp = [ePOHelp]::new()
                $TestHelp.CommandName = $Parameters.Command
                It "Get-ePOHelp With Pipeline" {
                    { $script:RequestResponse = ($TestHelp | Get-ePOHelp) } | Should Not Throw
                }
            } else {
                It "Get-ePOHelp" {
                    { $script:RequestResponse = Get-ePOHelp @parameters } | Should Not Throw
                }
            }


            It "Output Type: $($Test.Output.Type)" {
                $script:RequestResponse.GetType().FullName | Should Be $Test.Output.Type
            }

            if ($Test.Output.Type -eq 'System.Object[]') {
                It "Contains ePOHelp objects" {
                    foreach ($HelpItem in $RequestResponse) {
                        $HelpItem.GetType().FullName | Should Be 'ePOHelp'
                    }
                }
            }
        }
    }
}