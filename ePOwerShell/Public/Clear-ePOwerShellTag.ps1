function Clear-ePOwerShellTag {
    [CmdletBinding()]
    [Alias('Clear-ePOTag')]
    param (
        [Parameter(Mandatory = $True, Position = 1)]
        [String[]]
        $ComputerName,

        [Parameter(Mandatory = $True, Position = 2)]
        [String[]]
        $TagName
    )

    foreach ($Computer in $ComputerName) {
        Write-Verbose ('Clearing from computer: {0}' -f $Computer)

        foreach ($Tag in $TagName) {
            Write-Verbose ('Clearing tag: {0}' -f $Tag)
            $Request = @{
                Name     = 'system.clearTag'
                PassThru = $True
                Query    = @{
                    names   = $Computer
                    tagName = $Tag
                }
            }

            Write-Debug ('Request: {0}' -f ($Request | Out-String))
            try {
                $Result = Invoke-ePOwerShellRequest @Request
            } catch {
                Throw $_
            }

            Write-Debug ('Result: {0}' -f $Result)

            if ($Result -eq 0) {
                Write-Verbose ('Tag [{0}] is already cleared from computer {1}' -f $Tag, $Computer)
            } elseif ($Result -eq 1) {
                Write-Verbose ('Successfully cleared tag [{0}] to computer {1}' -f $Tag, $Computer)
            } else {
                Throw ('Unknown response: {0}' -f $Result)
            }
        }
    }
}