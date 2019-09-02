<#
    .SYNOPSIS
        Applies tags to computers managed in ePO

    .DESCRIPTION
        Using the supplied ComputerName(s) and TagName(s), we can apply the tag to the computers
        specified. Tags or Computers can be passed in through the pipeline, but not both at the same time.

    .EXAMPLE
        Set-ePOTag -Computer $Computer -Tag $Tag

        Set a single tag on a single computer

    .EXAMPLE
        Set-ePOTag @(Computer1, Computer2) Tag1

        Set one tag on two computers

    .EXAMPLE
        Set-ePOTag Computer1 @(Tag1, Tag2)

        Set two tags to a single computer:

    .PARAMETER ComputerName
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

function Set-ePOTag {
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "Medium")]
    [Alias('Set-ePOwerShellTag')]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Alias('Computer', 'cn')]
        $ComputerName,

        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $True)]
        [Alias('Tag')]
        $TagName
    )

    begin {
        try {
            $Request = @{
                Name  = 'system.applyTag'
                Query = @{
                    names   = ''
                    tagName = ''
                    ids     = ''
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        try {
            foreach ($Computer in $ComputerName) {
                foreach ($Tag in $TagName) {
                    if ($Computer -is [ePOComputer]) {
                        $Request.Query.ids = $Computer.ParentID
                    } elseif ($Computer -is [ePOTag]) {
                        $Request.Query.tagName = $Computer.Name
                    } else {
                        $Request.Query.names = $Computer
                    }

                    if ($Tag -is [ePOTag]) {
                        $Request.Query.tagName = $Tag.Name
                    } elseif ($Tag -is [ePOComputer]) {
                        $Request.Query.ids = $Tag.ParentID
                    } else {
                        $Request.Query.tagName = $Tag
                    }

                    if (!($Request.Query.names -eq '')) { Write-Verbose ('Computer Name: {0}' -f $Request.Query.names) }
                    if (!($Request.Query.ids -eq '')) { Write-Verbose ('Computer ID: {0}' -f $Request.Query.ParentID) }
                    Write-Verbose ('Tag Name: {0}' -f $Request.Query.tagName)

                    if ($PSCmdlet.ShouldProcess("Apply ePO tag $($Request.Query.tagName) to $($Request.Query.names)")) {
                        $Result = Invoke-ePORequest @Request

                        if ($Result -eq 0) {
                            Write-Verbose ('Tag [{0}] is already applied to computer {1}' -f $Tag, $Computer)
                        } elseif ($Result -eq 1) {
                            Write-Verbose ('Successfully applied tag [{0}] to computer {1}' -f $Tag, $Computer)
                        } else {
                            Write-Error ('Unknown response while applying tag [{0}] to {1}: {2}' -f $Tag, $Computer, $Result) -ErrorAction Stop
                        }
                    }
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end { }
}

Export-ModuleMember -Function 'Set-ePOTag' -Alias 'Set-ePOwerShellTag'
