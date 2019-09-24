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
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "High", DefaultParameterSetName = 'Computer')]
    [Alias('Clear-ePOwerShellTag', 'Clear-ePOTag')]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True, ParameterSetName = 'Computer')]
        [Alias('ComputerName', 'cn', 'Name')]
        $Computer,

        [Parameter(Mandatory = $True, ParameterSetName = 'AgentGuid')]
        $AgentGuid,

        [Parameter(Mandatory = $True, Position = 1, ValueFromPipeline = $True)]
        [Alias('Tag')]
        $TagName
    )

    begin {
        try {
            $Request = @{
                Name  = 'system.clearTag'
                Query = @{
                    ids   = ''
                    tagID = ''
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'Computer' {
                    :Computer foreach ($Comp in $Computer) {
                        :Tag foreach ($Tag in $TagName) {
                            if ($Comp -is [ePOTag] -and $Tag -is [ePOComputer]) {
                                Write-Verbose 'Computer and tag objects are mismatched. Swapping...'
                                $Comp, $Tag = $Tag, $Comp
                            }

                            if ($Comp -is [ePOComputer]) {
                                $Request.Query.ids = $Comp.ParentID
                            } elseif ($Comp -is [String]) {
                                Write-Verbose ('Searching for computer based off of name: {0}' -f $Comp)

                                if (-not ($Comp = Get-ePOComputer -Computer $Comp)) {
                                    Write-Error 'Failed to find a computer with provided name'
                                    continue Computer
                                }
                                $Request.Query.ids = $Comp.ParentID
                            } else {
                                Write-Error 'Failed to interpret computer'
                                continue Computer
                            }

                            if ($Tag -is [ePOTag]) {
                                $Request.Query.tagID = $Tag.ID
                            } elseif ($Tag -is [String]) {
                                Write-Verbose ('Searching for tag based off of name: {0}' -f $Tag)

                                if (-not ($Tag = Get-ePOTag -Tag $Tag)) {
                                    Write-Error 'Failed to find a tag with provided name'
                                    continue Tag
                                }
                                $Request.Query.tagID = $Tag.ID
                            } else {
                                Write-Error 'Failed to interpret tag'
                                continue Tag
                            }

                            Write-Verbose ('Computer Name: {0}' -f $Comp.ComputerName)
                            Write-Verbose ('Computer ID: {0}' -f $Comp.ParentID)
                            Write-Verbose ('Tag Name: {0}' -f $Tag.Name)
                            Write-Verbose ('Tag ID: {0}' -f $Tag.ID)

                            if ($PSCmdlet.ShouldProcess("Remove ePO tag $($Tag.Name) from $($Comp.ComputerName)")) {
                                $Result = Invoke-ePORequest @Request

                                if ($Result -eq 0) {
                                    Write-Verbose ('Tag [{0}] is already cleared from computer {1}' -f $Tag.Name, $Comp.ComputerName)
                                } elseif ($Result -eq 1) {
                                    Write-Verbose ('Successfully cleared tag [{0}] to computer {1}' -f $Tag.Name, $Comp.ComputerName)
                                } else {
                                    Write-Error ('Unknown response while clearing tag [{0}] from {1}: {2}' -f $Tag.Name, $Comp.ComputerName, $Result)
                                }
                            }
                        }
                    }
                }

                'AgentGuid' {
                    foreach ($Guid in $AgentGuid) {
                        if (-not ($ePOComputer = Get-ePOComputer -AgentGuid $Guid)) {
                            Write-Error ('Failed to find system via Agent Guid: {0}' -f $Guid)
                            continue
                        }

                        foreach ($Comp in $ePOComputer) {
                            :Tag foreach ($Tag in $TagName) {
                                $Request.Query.ids = $Comp.ParentID

                                if ($Tag -is [ePOTag]) {
                                    $Request.Query.tagID = $Tag.ID
                                } elseif ($Tag -is [String]) {
                                    Write-Verbose ('Searching for tag based off of name: {0}' -f $Tag)

                                    if (-not ($Tag = Get-ePOTag -Tag $Tag)) {
                                        Write-Error 'Failed to find a tag with provided name'
                                        continue Tag
                                    }
                                    $Request.Query.tagID = $Tag.ID
                                } else {
                                    Write-Error 'Failed to interpret tag'
                                    continue Tag
                                }

                                Write-Verbose ('Computer Name: {0}' -f $Comp.ComputerName)
                                Write-Verbose ('Computer ID: {0}' -f $Comp.ParentID)
                                Write-Verbose ('Tag Name: {0}' -f $Tag.Name)
                                Write-Verbose ('Tag ID: {0}' -f $Tag.ID)

                                if ($PSCmdlet.ShouldProcess("Remove ePO tag $($Tag.Name) from $($Comp.ComputerName)")) {
                                    $Result = Invoke-ePORequest @Request

                                    if ($Result -eq 0) {
                                        Write-Verbose ('Tag [{0}] is already cleared from computer {1}' -f $Tag.Name, $Comp.ComputerName)
                                    } elseif ($Result -eq 1) {
                                        Write-Verbose ('Successfully cleared tag [{0}] to computer {1}' -f $Tag.Name, $Comp.ComputerName)
                                    } else {
                                        Write-Error ('Unknown response while clearing tag [{0}] from {1}: {2}' -f $Tag.Name, $Comp.ComputerName, $Result)
                                    }
                                }
                            }
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