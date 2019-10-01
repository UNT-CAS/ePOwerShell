[System.String]    $ProjectDirectoryName = 'ePOwerShell'
[System.String]    $FunctionType         = 'Public'
[IO.FileInfo]      $PesterFile           = [IO.FileInfo] ([System.String] (Resolve-Path -Path $MyInvocation.MyCommand.Path))
[System.String]    $FunctionName         = $PesterFile.Name.Split('.')[0]
[IO.DirectoryInfo] $ProjectRoot          = Split-Path -Parent $PesterFile.Directory

while (-not ($ProjectRoot.Name -eq $ProjectDirectoryName)) {
    $ProjectRoot = Split-Path -Parent $ProjectRoot.FullName
}

[IO.DirectoryInfo] $ExampleDirectory          = Join-Path (Join-Path -Path $ProjectRoot -ChildPath 'Examples' -Resolve) -ChildPath $FunctionType -Resolve
[IO.DirectoryInfo] $ExampleDirectory          = Join-Path $ExampleDirectory.FullName -ChildPath $FunctionName -Resolve
[IO.DirectoryInfo] $Global:ReferenceDirectory = Join-Path $ExampleDirectory.FullName -ChildPath 'References' -Resolve

$Examples = Get-ChildItem $ExampleDirectory -Filter "*.psd1" -File

$Tests = foreach ($Example in $Examples) {
    [hashtable] $Test = @{
        Name = $Example.BaseName.Split('.')[1]
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"

    foreach ($ExampleData in (Import-PowerShellDataFile -LiteralPath $Example.FullName).GetEnumerator()) {
        $Test.Add($ExampleData.Name, $ExampleData.Value) | Out-Null
    }

    Write-Verbose "Test: $($Test | ConvertTo-Json)"
    Write-Output $Test
}

Describe $FunctionName {
    foreach ($Global:Test in $Tests) {
        InModuleScope ePOwerShell {
            Mock Get-ePOComputer {
                $ComputerFiles = Get-ChildItem $ReferenceDirectory.FullName -Filter 'Computer*.html' -File | Where-Object { $_.Name -notlike '*Results.html' }

                foreach ($File in $ComputerFiles) {
                    $ComputerObject = (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    $ComputerObject = ConvertTo-ePOComputer $ComputerObject

                    if ($Computer) {
                        if ($Computer -eq $ComputerObject.ComputerName) {
                            Write-Output $ComputerObject
                        }
                    } elseif ($AgentGuid) {
                        if ($AgentGuid -eq $ComputerObject.AgentGuid) {
                            Write-Output $ComputerObject
                        }
                    }
                }
            }

            Mock Get-ePOTag {
                $TagFiles = Get-ChildItem $ReferenceDirectory.FullName -Filter 'Tag*.html' -File

                foreach ($File in $TagFiles) {
                    $TagObject = (Get-Content $File.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json

                    if ($TagObject.TagName -eq $Tag) {
                        Write-Output $TagObject
                    }
                }

            }

            Mock Invoke-ePORequest {
                $ComputerFiles = Get-ChildItem $ReferenceDirectory.FullName -Filter 'Computer*.html' -File | Where-Object { $_.Name -notlike '*Results.html' }
                $TagFiles = Get-ChildItem $ReferenceDirectory.FullName -Filter 'Tag*.html' -File

                foreach ($ComputerFile in $ComputerFiles) {
                    $ComputerObject = (Get-Content $ComputerFile.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json
                    $ComputerObject = ConvertTo-ePOComputer $ComputerObject

                    if ($ComputerObject.ParentID -eq $Query.ids) {
                        break
                    }
                }

                foreach ($TagFile in $TagFiles) {
                    $TagObject = (Get-Content $TagFile.FullName | Out-String).Substring(3).Trim() | ConvertFrom-Json

                    if ($TagObject.tagId -eq $Query.tagID) {
                        break
                    }
                }

                if ($Test.Unknown) {
                    Write-Output 4
                } elseif ($ComputerObject.Tags -contains $TagObject.tagName) {
                    Write-Output 1
                } else {
                    Write-Output 0
                }
            }

            Mock Write-Warning {
                Write-Debug $Message
            }

            Mock Write-Error {
                Throw $_
            }

            Mock Write-Information {
                Throw $_
            }

            Remove-Variable -Scope 'Script' -Name 'RequestResponse' -Force -ErrorAction SilentlyContinue

            Context $Test.Name {
                [hashtable] $parameters = $Test.Parameters

                if ($Test.Output.Throws) {
                    It "Remove-ePOTag Throws" {
                        { $script:RequestResponse = Remove-ePOTag @parameters -Confirm:$False } | Should Throw
                    }
                    continue
                }

                It "Remove-ePOTag" {
                    { $script:RequestResponse = Remove-ePOTag @parameters -Confirm:$False } | Should Not Throw
                }

                It "Output Type: $($Test.Output.Type)" {
                    $script:RequestResponse | Should BeNullOrEmpty
                }
            }
        }
    }

    Remove-Variable -Scope 'Global' -Name 'Test' -Force -ErrorAction SilentlyContinue
    Remove-Variable -Scope 'Global' -Name 'ReferenceDirectory' -Force -ErrorAction SilentlyContinue
}