<#
.SYNOPSIS

    Returns the MNE Recovery Key for specified encrypted systems

.DESCRIPTION

    Returns the MNE Recovery Key for specified encrypted systems. If no key is found, throws a warning    

.EXAMPLE

    Get-ePORecoveryKey 'My-ComputerName'
#>

function Get-ePORecoveryKey {
    [CmdletBinding(DefaultParametersetname = 'Computer')]
    [Alias('Get-ePOwerShellMneRecoveryKey', 'Get-ePOMneRecoveryKey')]
    [OutputType([System.Object[]])]
    param (
        <#
            .PARAMETER Computer
                Specifies either an ePOComputer object or the system name found in ePO
        #>
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        [Alias('Name')]
        $Computer
    )

    begin {
        try {
            [System.Collections.ArrayList] $Found = @()
            
            $Request = @{
                Name        = 'mne.recoverMachine'
                Query       = @{
                    serialNumber = ''
                }
                ErrorAction = 'Stop'
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
            } else {
                Write-Verbose 'Computer is not an ePOComputer object. Searching for...'
                $Comp = Get-ePOComputer -Computer $Comp -ErrorAction Stop
            }

            $QueryRequest = @{
                Table = 'MneVolumes'
                Select = @(
                    'MneFvRecoveryKeys.DisplayName',
                    'MneVolumes.MountPoint'
                )
                Where = @{
                    eq = @{
                        'MneVolumes.EPOLeafNodeId' = $Comp.ParentID
                    }
                }
                ErrorAction = 'Stop'
            }

            $MountPoints = Invoke-ePOQuery @QueryRequest

            foreach ($MountPoint in $MountPoints) {
                Write-Verbose ('Getting recovery key for mount point: {0}' -f $MountPoint.'MneFvRecoveryKeys.DisplayName')
                $Request.Query.serialNumber = $MountPoint.'MneFvRecoveryKeys.DisplayName'

                $RecoveryKey = Invoke-ePORequest @Request
                $RecoveryKeyObject = [ePORecoveryKey]::new($Comp.ComputerName, $MountPoint.'MneVolumes.MountPoint', $RecoveryKey)
                [Void] $Found.Add($RecoveryKeyObject)
            }
        }
    }

    end {
        try {
            Write-Output $Found
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}