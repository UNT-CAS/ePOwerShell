<#
    .SYNOPSIS
        Returns the MNE Recovery Key for specified encrypted systems

    .DESCRIPTION
        For the provided computer(s), this will query the ePO servers to find all of the encrypted volumes.
        For each volume, it collects the mount point and the volume serial number stored in ePO. For each of
        the encrypted volumes, it queries for a recovery key. The problem with only querying against the ePO
        Leaf Node ID is that it only returns a recovery key for the systems boot volume. If the system has
        additional mounted drives that are also encrypted, it does not return these keys.

        This function outputs an array of ePORecoveryKey objects containing the computer name, mount point,
        and recovery key.

    .EXAMPLE
        $RecoveyKey = Get-ePORecoveryKey -Computer 'My-ComputerName'

        Fetch the recovery key for a system

    .PARAMETER Computer
        Specifies the computer we're finding the recovery key for. Can be provided as:

            * An ePOComputer object
            * A computer name

        This parameter can be passed in from the pipeline.
#>

function Get-ePORecoveryKey {
    [CmdletBinding(DefaultParametersetname = 'Computer')]
    [Alias('Get-ePOwerShellMneRecoveryKey', 'Get-ePOMneRecoveryKey')]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Alias('ComputerName', 'Name')]
        $Computer
    )

    begin {
        try {
            $Request = @{
                Name        = 'mne.recoverMachine'
                Query       = @{
                    serialNumber = ''
                }
                ErrorAction = 'Stop'
            }

            if ($Computer) {
                $Computer = $Computer.Split(',').Trim()
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        foreach ($Comp in $Computer) {
            if ($Comp -is [ePOComputer]) {
                Write-Verbose 'Computer is an ePOComputer object'
                $CompResponse = $Comp
            } else {
                Write-Verbose 'Computer is not an ePOComputer object. Searching for...'
                $CompResponse = Get-ePOComputer -Computer $Comp -ErrorAction Stop
            }

            foreach ($Item in $CompResponse) {
                Write-Verbose ('Detecting mount points for {0}' -f $Item.ComputerName)
                $QueryRequest = @{
                    Table       = 'MneVolumes'
                    Select      = @(
                        'MneFvRecoveryKeys.DisplayName',
                        'MneVolumes.MountPoint'
                    )
                    Where       = @{
                        eq = @{
                            'MneVolumes.EPOLeafNodeId' = $Item.ParentID
                        }
                    }
                    ErrorAction = 'Stop'
                }

                Write-Debug ('Mount point query request: {0}' -f ($QueryRequest | ConvertTo-Json))

                $MountPoints = Invoke-ePOQuery @QueryRequest

                if ($MountPoints.Count -eq 0) {
                    Write-Error ('Failed to find mount points for {0}, {1}' -f $Item.ComputerName, $Item.ParentID)
                    continue
                }

                Write-Debug ('Mount points: {0}' -f ($MountPoints -join ', '))

                foreach ($MountPoint in $MountPoints) {
                    Write-Verbose ('Getting recovery key for mount point: {0}' -f $MountPoint.'MneFvRecoveryKeys.DisplayName')
                    $Request.Query.serialNumber = $MountPoint.'MneFvRecoveryKeys.DisplayName'

                    $RecoveryKey = Invoke-ePORequest @Request
                    $RecoveryKeyObject = [ePORecoveryKey]::new($Item.ComputerName, $MountPoint.'MneVolumes.MountPoint', $RecoveryKey)
                    Write-Output $RecoveryKeyObject
                }
            }
        }
    }

    end {}
}

Export-ModuleMember -Function 'Get-ePORecoveryKey' -Alias 'Get-ePOwerShellMneRecoveryKey', 'Get-ePOMneRecoveryKey'