<#
.SYNOPSIS

    Applies tags to computers managed in ePO

.DESCRIPTION

    Using the supplied ComputerName(s) and TagName(s), we can apply the tag to the computers
    specified

.PARAMETER ComputerName

    Specifies the name of the computer managed by ePO to have a tag applied to it. Computer names
    can be found using Find-ePOwerShellComputerSystem.

.PARAMETER TagName

    Specifies the name of the tag to be applied. Tag names can be found using Find-ePOwerShellTag

.EXAMPLE

    Set-ePOwerShellTag Computer1 Tag1

.EXAMPLE

    Set-ePOwerShellTag @(Computer1, Computer2) Tag1

.EXAMPLE

    Set-ePOwerShellTag Computer1 @(Tag1, Tag2)
#>

function Set-ePOwerShellTag {
    [CmdletBinding()]
    [Alias('Set-ePOTag')]
    param (
        [Parameter(Mandatory = $True, Position = 0)]
        [String[]]
        $ComputerName,

        [Parameter(Mandatory = $True, Position = 1)]
        [String[]]
        $TagName
    )

    foreach ($Computer in $ComputerName) {
        Write-Verbose ('Applying to computer: {0}' -f $Computer)

        foreach ($Tag in $TagName) {
            Write-Verbose ('Applying tag: {0}' -f $Tag)
            $Request = @{
                Name  = 'system.applyTag'
                PassThru = $True
                Query = @{
                    names = $Computer
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
                Write-Verbose ('Tag [{0}] is already applied to computer {1}' -f $Tag, $Computer)
            } elseif ($Result -eq 1) {
                Write-Verbose ('Successfully applied tag [{0}] to computer {1}' -f $Tag, $Computer)
            } else {
                Throw ('Unknown response: {0}' -f $Result)
            }
        }
    }
}