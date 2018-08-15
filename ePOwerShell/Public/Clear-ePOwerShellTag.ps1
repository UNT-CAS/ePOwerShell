<#
.SYNOPSIS

    Removes a tag from a specified computer system

.DESCRIPTION

    Ensures that a tag is cleared from the specicied computer system, whether
    that means it wasn't applied to begin with, or it removes it from the system.

.PARAMETER ComputerName

    Specifies a computer system the tag will be removed from.

.PARAMETER TagName

    Specifies a tag to be removed from the specified computer system

.EXAMPLE

    Clear-ePOwerShellTag Computer1 Tag1

#>

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