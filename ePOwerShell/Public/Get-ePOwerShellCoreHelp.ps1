function Get-ePOwerShellCoreHelp {
    [CmdletBinding()]
    [Alias('Get-ePOCoreHelp')]
    param (
        [String]
        $Command,

        [Hashtable]
        $Request = @{
            Name = 'core.help'
        }
    )

    begin {
        if ($Command) {
            $Request.Add('Query', @{})
            $Request.Query.Add('Command', $Command)
        }
    }

    process {
        $Response = Invoke-ePOwerShellRequest @Request
        [System.Collections.ArrayList] $Help = @()

        foreach ($Item in $Response) {
            $Line = ($Item -Replace '\r\n', ' ')
            $FirstOutcome = [Regex]::Match($Item, '(\S+\.\S+)(.*)')
            $Command = $FirstOutcome.Groups[1].Value.Trim()

            [System.Collections.ArrayList] $Parameters = @()
            $PartTwo = $FirstOutcome.Groups[2].Value.Trim()

            if ($PartTwo -match ' - ') {
                $SecondOutcome = [Regex]::Match($PartTwo, '(\S+.*) - (\S+.*)')

                foreach ($item in ($SecondOutcome.Groups[1].Value -Split ' ')) {
                    $Parameters += $item.Trim()
                }

                $ContextMessage = ($SecondOutcome.Groups[2].Value -Replace ' - ', '').Trim()
            } else {
                $ContextMessage = ($FirstOutcome.Groups[2].Value -Replace ' - ', '').Trim()
            }


            [Hashtable] $HelpItem = @{
                Command = $Command
                Parameters = $Parameters
                Context = $ContextMessage
            }

            $Help += $HelpItem
        }
    }

    end {
        return ($Help | % { [PSCustomObject]$_ } | Format-Table -Property Command, Parameters, Context)
    }
}