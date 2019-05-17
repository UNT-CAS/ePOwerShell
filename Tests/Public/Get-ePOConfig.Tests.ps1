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
if ($FunctionType -eq 'Private') {
    [IO.FileInfo]  $TestFile             = Join-Path -Path $PrivateDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.', '.') -Resolve
} else {
    [IO.FileInfo]  $TestFile             = Join-Path -Path $PublicDirectory -ChildPath ($PesterFile.Name -replace '\.Tests\.', '.') -Resolve
}

. $TestFile
Get-ChildItem -Path $PublicDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }
Get-ChildItem -Path $PrivateDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }
Get-ChildItem -Path $ClassesDirectory -Filter '*.ps1' | ForEach-Object { . $_.FullName }

[System.Collections.ArrayList] $tests = @()
$examples = Get-ChildItem $exampleDirectory -Filter "$($testFile.BaseName).*.psd1" -File

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
                It "Get-ePOConfig Throws" {
                    { $script:RequestResponse = Get-ePOConfig @parameters } | Should Throw
                }
                continue
            }

            It "Get-ePOConfig" {
                { $script:ReturnResponse = Get-ePOConfig @parameters } | Should Not Throw
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