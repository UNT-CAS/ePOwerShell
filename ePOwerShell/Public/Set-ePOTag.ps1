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
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "Medium", DefaultParameterSetName = 'Computer')]
    [Alias('Set-ePOwerShellTag')]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True, ParameterSetName = 'Computer')]
        [Alias('ComputerName', 'cn')]
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
                Name  = 'system.applyTag'
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
                                if (-not ($Comp = Get-ePOComputer -Computer $Comp)) {
                                    Write-Error ('Failed to find a computer with provided name: {0}' -f $Comp)
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
                                if (-not ($Tag = Get-ePOTag -Tag $Tag)) {
                                    Write-Error ('Failed to find a tag with provided name: {0}' -f $Tag)
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

                            if ($PSCmdlet.ShouldProcess("Set ePO tag $($Tag.Name) to $($Comp.ComputerName)")) {
                                $Result = Invoke-ePORequest @Request

                                if ($Result -eq 0) {
                                    Write-Verbose ('Tag [{0}] is already set to computer {1}' -f $Tag.Name, $Comp.ComputerName)
                                } elseif ($Result -eq 1) {
                                    Write-Verbose ('Successfully set tag [{0}] to computer {1}' -f $Tag.Name, $Comp.ComputerName)
                                } else {
                                    Write-Error ('Unknown response while setting tag [{0}] from {1}: {2}' -f $Tag.Name, $Comp.ComputerName, $Result) -ErrorAction Stop
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
                            foreach ($Tag in $TagName) {
                                $Request.Query.ids = $Comp.ParentID

                                if ($Tag -is [ePOTag]) {
                                    $Request.Query.tagID = $Tag.ID
                                } elseif ($Tag -is [String]) {
                                    if (-not ($Tag = Get-ePOTag -Tag $Tag)) {
                                        Write-Error ('Failed to find a tag with provided name: {0}' -f $Tag)
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

                                if ($PSCmdlet.ShouldProcess("Set ePO tag $($Tag.Name) to $($Comp.ComputerName)")) {
                                    $Result = Invoke-ePORequest @Request

                                    if ($Result -eq 0) {
                                        Write-Verbose ('Tag [{0}] is already set from computer {1}' -f $Tag.Name, $Comp.ComputerName)
                                    } elseif ($Result -eq 1) {
                                        Write-Verbose ('Successfully set tag [{0}] to computer {1}' -f $Tag.Name, $Comp.ComputerName)
                                    } else {
                                        Write-Error ('Unknown response while set tag [{0}] from {1}: {2}' -f $Tag.Name, $Comp.ComputerName, $Result)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {}
}

Export-ModuleMember -Function 'Set-ePOTag' -Alias 'Set-ePOwerShellTag'