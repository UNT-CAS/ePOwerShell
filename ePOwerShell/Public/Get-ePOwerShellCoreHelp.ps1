function Get-ePOwerShellCoreHelp {
    [CmdletBinding()]
    [Alias('Get-ePOCoreHelp')]
    param (
        [String]
        $Command,

        [Hashtable]
        $Request = @{
            Name        = 'core.help'
            SkipOutput  = $True
        }
    )

    begin {
        if ($Command) {
            $Request.Add('Command', $Command)
        }
    }

    process {
        $Response = Invoke-ePOwerShellRequest @Request
    }

    end {
        return $Response
    }
}