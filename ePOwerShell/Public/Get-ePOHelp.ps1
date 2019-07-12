<#
    .SYNOPSIS
        Fetchs and returns the content from ePOs core.help menu.

    .DESCRIPTION
        Fetches all commands from the ePOs core.help menu. If a command is specified, the function will
        only return a single command. Each command is converted to an ePOHelp object containing 3 values:

            * Command
            * Parameters
            * Description

        The function will then return an array containing all ePOHelp objects.

    .EXAMPLE
        $Help = Get-ePOHelp

        Get all help objects on the ePO servers core.help page.

    .EXAMPLE
        $FindHelp = Get-ePOHelp -Command 'system.find'

        Get a single help object from the ePO servers core.help page.

    .PARAMETER Command
        Specifies a command the be queried from the ePO server
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

                Write-Output $HelpObject
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {}
}

Export-ModuleMember -Function 'Get-ePOHelp' -Alias 'Get-ePOwerShellCoreHelp', 'Get-ePOCoreHelp'