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

function Set-ePOTag {
    [CmdletBinding(SupportsShouldProcess = $True)]
    [Alias('Set-ePOwerShellTag')]
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
                Name     = 'system.applyTag'
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
        
                    if ($PSCmdlet.ShouldProcess("Set ePO tag $($Request.Query.tagName) from $($Request.Query.names)")) {
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