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

.PARAMETER Passthru

    If called, function returns the raw content from the ePO server

.EXAMPLE

    Get-ePOwerShellCoreHelp

.EXAMPLE

    Get-ePOwerShellCoreHelp 'system.find'

.EXAMPLE

    Get-ePOwerShellCoreHelp -PassThru
#>

function Get-ePOwerShellCoreHelp {
    [CmdletBinding()]
    [Alias('Get-ePOCoreHelp')]
    param (
        [Parameter(Position = 1)]
        [String]
        $Command,

        [Switch]
        $PassThru
    )

    $Request = @{
        Name        = 'core.help'
        PassThru    = $PassThru
    }

    if ($Command) {
        $Request.Add('Query', @{})
        $Request.Query.Add('Command', $Command)
    }

    $Response = Invoke-ePOwerShellRequest @Request

    if ($PassThru) {
        return $Response
    }

    [System.Collections.ArrayList] $Commands = @()

    foreach ($Item in $Response) {
        $Item = $Item -replace '\r\n', ' '
        $FirstRegexProduct = [Regex]::Match($Item, '^(\S+)\s(.*)$')
        $LocalCommand = $FirstRegexProduct.Groups[1].Value
        $Remainder = $FirstRegexProduct.Groups[2].Value

        if ($Remainder -match '^\-.*') {
            $Remainder = $Remainder.TrimStart('- ')
        }

        if ($Remainder -match '\s\-\s') {
            $SecondRegexProduct = [Regex]::Match($Remainder, '(^\S+.{0,})\s\-\s(\S+.{0,})$')

            [System.Collections.ArrayList] $Parameters = @()

            foreach ($Parameter in ($SecondRegexProduct.Groups[1].Value -Split ' ')) {
                $Parameters.Add($Parameter) | Out-Null
            }

            $Description = $SecondRegexProduct.Groups[2].Value
        }
        else {
            $Parameters = $null
            $Description = $Remainder
        }

        $Commands.Add(
            @{
                Command     = $LocalCommand
                Parameters  = $Parameters
                Description = $Description
            }
        ) | Out-Null
    }

    return ($Commands | % { [PSCustomObject]$_ } | Format-Table -Property Command, Parameters, Description)
}