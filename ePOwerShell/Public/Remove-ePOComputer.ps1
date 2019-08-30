<#
    .SYNOPSIS
        Removes computers managed in ePO

    .DESCRIPTION
        Using the supplied ComputerName(s), we can remove the computer specified from ePO

    .EXAMPLE
        Remove-ePOComputer -Computer $Computer

        Remove a single tag on a single computer

    .EXAMPLE
        Remove-ePOComputer -Computer @(Computer1, Computer2)

        Remove one tag on two computers

    .EXAMPLE
        Get-ePOComputer My-Computer123 | Remove-ePOComputer

        Remove a single computer through the pipeline

    .PARAMETER Computer
        Specifies the name of the computer managed by ePO to be removed. This can be provided by:

            * An ePOComputer object
            * A computer name

        This parameter can be provided through the pipeline

    .OUTPUTS
        None
#>

function Remove-ePOComputer {
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "High", DefaultParameterSetName = 'Computer')]
    param (
        [Parameter(Mandatory = $True, ParameterSetName = 'Computer', Position = 0, ValueFromPipeline = $True)]
        [Alias('ComputerName', 'cn', 'Name')]
        $Computer,

        [Parameter(Mandatory = $True, ParameterSetName = 'AgentGuid')]
        $AgentGuid
    )

    begin {
        try {
            $Request = @{
                Name  = 'system.delete'
                Query = @{
                    ids = ''
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
                    foreach ($Comp in $Computer) {
                        if ($Comp -is [ePOComputer]) {
                            Write-Debug ('Specified computer is an ePOComputer: -f {0}' -f $Comp)
                        } else {
                            Write-Debug ('Specified computer is a string: -f {0}' -f $Comp)
                            $Comp = Get-ePOComputer $Comp
                        }

                        foreach ($C in $Comp) {
                            Write-Verbose ('Computer Name: {0}' -f $C.ComputerName)
                            Write-Verbose ('Computer ID: {0}' -f $C.ParentID)

                            $Request.Query.ids = $C.ParentID
                            if ($PSCmdlet.ShouldProcess("Remove ePO computer: $($C.ComputerName)")) {
                                $Result = Invoke-ePORequest @Request

                                if ($Result -eq 0) {
                                    Write-Verbose ('Deleted computer: {0}' -f $C.ComputerName)
                                } else {
                                    Throw ('Unknown response while deleting computer {0} from ePO: {1}' -f $C.ComputerName, $Result)
                                }
                            }
                        }
                    }
                }

                'AgentGuid' {
                    foreach ($Guid in $AgentGuid) {
                        if (-not ($Comp = Get-ePOComputer -AgentGuid $Guid)) {
                            Write-Error ('Failed to find system via Agent Guid: {0}' -f $Guid)
                            continue
                        }

                        foreach ($C in $Comp) {
                            Write-Verbose ('Computer Name: {0}' -f $C.ComputerName)
                            Write-Verbose ('Computer ID: {0}' -f $C.ParentID)

                            $Request.Query.ids = $C.ParentID
                            if ($PSCmdlet.ShouldProcess("Remove ePO computer: $($C.ComputerName)")) {
                                $Result = Invoke-ePORequest @Request

                                if ($Result -eq 0) {
                                    Write-Verbose ('Deleted computer: {0}' -f $C.ComputerName)
                                } else {
                                    Throw ('Unknown response while deleting computer {0} from ePO: {1}' -f $C.ComputerName, $Result)
                                }
                            }
                        }
                    }
                }
            }
        } catch {
            Write-Error $_
        }
    }
}

Export-ModuleMember -Function 'Remove-ePOComputer'