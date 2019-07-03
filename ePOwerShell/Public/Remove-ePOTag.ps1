<#
    .SYNOPSIS
        Removes tags from computers managed in ePO

    .DESCRIPTION
        Using the supplied ComputerName(s) and TagName(s), we can remove the tag to the computers
        specified. Tags or Computers can be passed in through the pipeline, but not both at the same time.

    .EXAMPLE
        Remove a single tag on a single computer
        ```powershell
        $Tag = Get-ePOTag -Tag 'Tag1'
        $Computer = Get-ePOComputer -Computer 'Computer1'
        Remove-ePOTag -Computer $Computer -Tag $Tag
        ```

    .EXAMPLE
        Remove one tag on two computers
        ```powershell
        Remove-ePOTag @(Computer1, Computer2) Tag1
        ```

    .EXAMPLE
        Remove two tags to a single computer:
        ```powershell
        Remove-ePOTag Computer1 @(Tag1, Tag2)
        ```
#>

function Remove-ePOTag {
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "High")]
    [Alias('Clear-ePOwerShellTag', 'Clear-ePOTag')]
    param (
        <#
            .PARAMETER Computer
                Specifies the name of the computer managed by ePO to have a tag applied to it. This can be provided by:

                    * An ePOComputer object
                    * A computer name

                This parameter can be provided through the pipeline
        #>
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Alias('Computer', 'cn', 'Name')]
        $ComputerName,

        <#
            .PARAMETER Tag
                Specifies the name of the tag to be applied. This can be provided by:

                    * An ePOTag object
                    * A tag name

                This parameter can be provided through the pipeline
        #>
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
            foreach ($Computer in $ComputerName) {
                foreach ($Tag in $TagName) {
                    if ($Computer -is [ePOComputer]) {
                        $Request.Query.names = $Computer.ComputerName
                    } elseif ($Computer -is [ePOTag]) {
                        $Request.Query.tagName = $Computer.Name
                    } else {
                        $Request.Query.names = $Computer
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
                            Write-Verbose ('Tag [{0}] is already cleared from computer {1}' -f $Tag, $Computer)
                        } elseif ($Result -eq 1) {
                            Write-Verbose ('Successfully cleared tag [{0}] to computer {1}' -f $Tag, $Computer)
                        } else {
                            Write-Error ('Unknown response while clearing tag [{0}] from {1}: {2}' -f $Tag, $Computer, $Result)
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