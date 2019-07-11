<#
    .SYNOPSIS
        Removes tags from computers managed in ePO

    .DESCRIPTION
        Using the supplied ComputerName(s) and TagName(s), we can remove the tag to the computers
        specified. Tags or Computers can be passed in through the pipeline, but not both at the same time.

    .EXAMPLE
        Remove-ePOTag -Computer $Computer -Tag $Tag

        Remove a single tag on a single computer

    .EXAMPLE
        Remove-ePOTag -Computer @(Computer1, Computer2) -Tag Tag1

        Remove one tag on two computers

    .EXAMPLE
        Remove-ePOTag Computer1 @(Tag1, Tag2)

        Remove two tags to a single computer

    .PARAMETER Computer
        Specifies the name of the computer managed by ePO to have a tag applied to it. This can be provided by:

            * An ePOComputer object
            * A computer name

        This parameter can be provided through the pipeline

    .PARAMETER Tag
        Specifies the name of the tag to be applied. This can be provided by:

            * An ePOTag object
            * A tag name

        This parameter can be provided through the pipeline

    .OUTPUTS
        None
#>

function Remove-ePOTag {
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "High")]
    [Alias('Clear-ePOwerShellTag', 'Clear-ePOTag')]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Alias('ComputerName', 'cn', 'Name')]
        $Computer,

        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $True)]
        [Alias('Tag')]
        $TagName
    )

    begin {
        try {
            $Request = @{
                Name  = 'system.clearTag'
                Query = @{
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
            foreach ($Comp in $Computer) {
                foreach ($Tag in $TagName) {
                    if ($Comp -is [ePOComputer]) {
                        $Request.Query.names = $Comp.ComputerName
                    } elseif ($Comp -is [ePOTag]) {
                        $Request.Query.tagName = $Comp.Name
                    } else {
                        $Request.Query.names = $Comp
                    }

                    if ($Tag -is [ePOTag]) {
                        $Request.Query.tagName = $Tag.Name
                    } elseif ($T -is [ePOComputer]) {
                        $Request.Query.names = $Tag.ComputerName
                    } else {
                        $Request.Query.tagName = $Tag
                    }

                    Write-Verbose ('Computer Name: {0}' -f $Request.Query.names)
                    Write-Verbose ('Tag Name: {0}' -f $Request.Query.tagName)

                    if ($PSCmdlet.ShouldProcess("Remove ePO tag $($Request.Query.tagName) from $($Request.Query.names)")) {
                        $Result = Invoke-ePORequest @Request

                        if ($Result -eq 0) {
                            Write-Verbose ('Tag [{0}] is already cleared from computer {1}' -f $Tag, $Comp)
                        } elseif ($Result -eq 1) {
                            Write-Verbose ('Successfully cleared tag [{0}] to computer {1}' -f $Tag, $Comp)
                        } else {
                            Write-Error ('Unknown response while clearing tag [{0}] from {1}: {2}' -f $Tag, $Comp, $Result)
                        }
                    }
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
        }
    }

    end {}
}

Export-ModuleMember -Function 'Remove-ePOTag' -Alias 'Clear-ePOwerShellTag', 'Clear-ePOTag'