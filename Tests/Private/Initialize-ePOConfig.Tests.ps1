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
if ($FunctionType -eq 'Private') {
    [IO.FileInfo]  $TestFile             = Join-Path -Path $PrivateDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.', '.') -Resolve
} else {
    [IO.FileInfo]  $TestFile             = Join-Path -Path $PublicDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.', '.') -Resolve
}

. $TestFile
Get-ChildItem -Path $PublicDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }

[System.Collections.ArrayList] $Tests = @()
$Examples = Get-ChildItem $ExampleDirectory -Filter "$($TestFile.BaseName).*.psd1" -File

foreach ($Example in $Examples) {
    [Hashtable] $Test = @{
        Name = $Example.BaseName.Replace("$($TestFile.BaseName).$Verb", '').Replace('_', ' ')
        Parameters = @{}
    }
    Write-Verbose "Test: $($Test | ConvertTo-Json)"

    foreach ($ExampleData in (Import-PowerShellDataFile -LiteralPath $Example.FullName).GetEnumerator()) {
        if (
            ($ExampleData.Name -eq 'Port') -or
            ($ExampleData.Name -eq 'Server')
        ) {
            $Test.Parameters.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
        } else {
            $Test.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
        }
    }

    $SuperSecretPassword = ConvertTo-SecureString $Test.Password -AsPlainText -Force
    $Credentials = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList ($Test.Username, $SuperSecretPassword)

    $Test.Parameters.Add('Credentials', $Credentials) | Out-Null

    Write-Verbose "Test: $($Test | ConvertTo-Json)"
    $Tests.Add($Test) | Out-Null
}


Describe $TestFile.Name {
    Mock Get-ePOHelp {
        if ($Test.CoreHelpFail) {
            Throw 'Failing Core.help'
        }
    }
    foreach ($Test in $Tests) {
        Remove-Variable -Scope 'Script' -Name 'ePOwerShell' -Force -ErrorAction SilentlyContinue

        Context $Test.Name {
            [Hashtable] $Parameters = $Test.Parameters

            if ($Test.Output.Throws) {
                It "Initialize-ePOConfig" {
                    { Initialize-ePOConfig @Parameters } | Should Throw
                }

                continue
            }

            It "Initialize-ePOConfig" {
                { Initialize-ePOConfig @Parameters } | Should Not Throw
            }

            It "`$ePOwerShell exists" {
                { $script:ePOwerShell } | Should Not BeNullOrEmpty
            }
        }
    }
}