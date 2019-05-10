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

    Remove-ePOTag Computer1 Tag1

#>

function Remove-ePOTag {
    [CmdletBinding(SupportsShouldProcess = $True)]
    [Alias('Clear-ePOwerShellTag', 'Clear-ePOTag')]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Alias('ComputerName')]
        $Computer,
        
        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $True)]
        [Alias('TagName')]
        $Tag
    )

    begin {
        try {
            $Request = @{
                Name     = 'system.clearTag'
                Query    = @{
                    names   = ''
                    tagName = ''
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        try {
            foreach ($C in $Computer) {
                foreach ($T in $Tag) {
                    if ($C -is [ePOComputer]) {
                        $Request.Query.names = $C.ComputerName
                    } elseif ($C -is [ePOTag]) {
                        $Request.Query.tagName = $C.Name
                    } else {
                        $Request.Query.names = $C
                    }

                    if ($T -is [ePOTag]) {
                        $Request.Query.tagName = $T.Name
                    } elseif ($T -is [ePOComputer]) {
                        $Request.Query.names = $T.ComputerName
                    } else {
                        $Request.Query.tagName = $T
                    }
                    
                    Write-Verbose ('Computer Name: {0}' -f $Request.Query.names)
                    Write-Verbose ('Tag Name: {0}' -f $Request.Query.tagName)

                    if ($PSCmdlet.ShouldProcess("Remove ePO tag $($Request.Query.tagName) from $($Request.Query.names)")) {
                        $Result = Invoke-ePORequest @Request

                        if ($Result -eq 0) {
                            Write-Verbose ('Tag [{0}] is already cleared from computer {1}' -f $T, $C)
                        } elseif ($Result -eq 1) {
                            Write-Verbose ('Successfully cleared tag [{0}] to computer {1}' -f $T, $C)
                        } else {
                            Write-Error ('Unknown response while clearing tag [{0}] from {1}: {2}' -f $T, $C, $Result) -ErrorAction Stop
                        }
                    }
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}