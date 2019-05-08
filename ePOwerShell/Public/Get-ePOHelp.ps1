<#
.SYNOPSIS

    Fetchs and returns the content from ePOs core.help menu

.DESCRIPTION

    Fetches all commands from the ePOs core.help menu. If PassThru is specifed, it returns the
    raw content from the server. If PassThru is not specified, then each command is broken down
    into 3 sections: Command, Parameters, and Description. The function will then return an array
    containing all commands and additional information.

.PARAMETER Command

    Specifies a command the be queried from the ePO server

.EXAMPLE
    Get-ePOHelp

.EXAMPLE
    Get-ePOHelp 'system.find'
#>

function Get-ePOHelp {
    [CmdletBinding()]
    [Alias('Get-ePOwerShellCoreHelp', 'Get-ePOCoreHelp')]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        $Command
    )

    begin {
        try {
            $Request = @{
                Name = 'core.help'
            }

            if ($Command) {
                $Request.Add('Query', @{})
                if ($Command -is [ePOHelp]) {
                    $Request.Query.Add('Command', $Command.CommandName)
                } else {
                    $Request.Query.Add('Command', $Command)
                }
            }

            [System.Collections.ArrayList] $Commands = @()
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        try {
            $Response = Invoke-ePORequest @Request

            foreach ($Item in $Response) {
                $HelpObject = [ePOHelp]::new()
                $Item = $Item -replace '\r\n', ' '

                $FirstRegexProduct = [Regex]::Match($Item, '^(\S+)\s(.*)$')
                $HelpObject.CommandName = $FirstRegexProduct.Groups[1].Value
                $Remainder = $FirstRegexProduct.Groups[2].Value

                if ($Remainder -match '^\-.*') {
                    $Remainder = $Remainder.TrimStart('- ')
                }

                if ($Remainder -match '\s\-\s') {
                    $SecondRegexProduct = [Regex]::Match($Remainder, '(^\S+.{0,})\s\-\s(\S+.{0,})$')
                    
                    $HelpObject.Parameters = ($SecondRegexProduct.Groups[1].Value -Split ' ').Trim('[').Trim(']')
                    $HelpObject.Description = $SecondRegexProduct.Groups[2].Value
                } else {
                    $HelpObject.Description = $Remainder
                }

                [Void] $Commands.Add($HelpObject)
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {
        try {
            Write-Output $Commands
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}