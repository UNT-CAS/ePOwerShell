[System.String]    $ProjectDirectoryName = 'ePOwerShell'
[System.String]    $FunctionType         = 'Private'
[IO.FileInfo]      $PesterFile           = [IO.FileInfo] ([System.String] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[System.String]    $FunctionName         = $PesterFile.Name.Split('.')[0]
[IO.DirectoryInfo] $ProjectRoot          = Split-Path -Parent $PesterFile.Directory

While (-not ($ProjectRoot.Name -eq $ProjectDirectoryName)) {
    $ProjectRoot = Split-Path -Parent $ProjectRoot.FullName
}

[IO.DirectoryInfo] $ProjectDirectory     = Join-Path -Path $ProjectRoot -ChildPath $ProjectDirectoryName -Resolve
[IO.DirectoryInfo] $PublicDirectory      = Join-Path -Path $ProjectDirectory -ChildPath 'Public' -Resolve 
[IO.DirectoryInfo] $PrivateDirectory     = Join-Path -Path $ProjectDirectory -ChildPath 'Private' -Resolve 
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



[System.Collections.ArrayList] $Tests = @()
$Examples = Get-ChildItem $exampleDirectory -Filter "$($testFile.BaseName).*.psd1" -File

foreach ($Example in $Examples) {
    [hashtable] $test = @{
        Name = $Example.BaseName.Replace("$($testFile.BaseName).$verb", '').Replace('_', ' ')
    }
    Write-Verbose "Test: $($test | ConvertTo-Json)"

    foreach ($ExampleData in (Import-PowerShellDataFile -LiteralPath $Example.FullName).GetEnumerator()) {
        $test.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
    }

    if ($test.Username -and $test.Password) {
        $SuperSecretPassword = ConvertTo-SecureString $test.Password -AsPlainText -Force
        $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.Username, $SuperSecretPassword)

        $test.ePOwerShell.Add('Credentials', $Credentials) | Out-Null
    }

    [Void] $Tests.Add($test)
}


Describe $TestFile.Name {
    foreach ($Test in $Tests) {
        Mock Invoke-WebRequest {
            if ($Test.BreakIWR) {
                Throw 'Breaking Invoke-WebRequest'
            }

            return @{
                Content = (Get-Content (Join-Path -Path $ReferenceDirectory -ChildPath ('{0}.html' -f $Test.Parameters.Name) -Resolve) | Out-String)
            }
        }

        Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue
        Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue

        if ($Test.ePOwerShell) {
            $script:ePOwerShell = $Test.ePOwerShell
        }

        Context $Test.Name {
            [Hashtable] $Parameters = $Test.Parameters

            if ($Test.Output.Throws) {
                It "Invoke-ePORequest Throws" {
                    { $script:RequestResponse = Invoke-ePORequest @parameters } | Should Throw
                }
                continue
            }

            It "Invoke-ePORequest" {
                { $Script:RequestResponse = Invoke-ePORequest @Parameters } | Should Not Throw
            }

            It "Output Type: $($test.Output.Type)" {
                if ($test.Output.Type -eq 'System.Void') {
                    $Script:RequestResponse | Should BeNullOrEmpty
                } else {
                    $Script:RequestResponse.GetType().FullName | Should Be $test.Output.Type
                }
            }
        }
    }
}