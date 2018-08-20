<#
.SYNOPSIS

    Returns the MNE Recovery Key for specified encrypted systems

.DESCRIPTION

    Returns the MNE Recovery Key for specified encrypted systems. If no key is found, throws a warning    

.PARAMETER LeafNodeId

    Specifies the unique Leaf Node ID for each individual computer

.PARAMETER SerialNumber

    Specifies the unique Serial Number for each individual computer

.EXAMPLE

    Get-ePOwerShellMneRecoveryKey '12345'

.EXAMPLE

    Get-ePOwerShellMneRecoveryKey -SerialNumber 'C035406KHV5K'
#>

function Get-ePOwerShellMneRecoveryKey {
    [CmdletBinding(DefaultParametersetname = 'LeafNode')]
    [Alias('Get-ePOMneRecoveryKey')]
    [OutputType([String])]
    param (
        [Parameter(Mandatory = $True, ParameterSetName = 'LeafNode', Position = 1)]
        [String[]]
        $LeafNodeId,

        [Parameter(Mandatory = $True, ParameterSetName = 'SerialNumber')]
        [String[]]
        $SerialNumber
    )

    $Request = @{
        Name        = 'mne.recoverMachine'
        PassThru    = $True
        Query       = @{}
    }

    [System.Collections.ArrayList] $Found = @()

    switch ($PSCmdlet.ParameterSetName) {
        'LeafNode' {
            $LeafNodeId = ($LeafNodeId -Split ',').Trim()
            foreach ($LeafNode in $LeafNodeId) {
                $Request.Query.epoLeafNodeId = $LeafNode
                
                try {
                    $Key = Invoke-ePOwerShellRequest @Request
                } catch {
                    Throw "Failed to find detect recovery key: $($_.Exception.Message)"
                }

                $Result = @{
                    LeafNodeId = $LeafNode
                    Key        = $Key
                }

                $Found.Add($Result) | Out-Null
            }
        }
        'SerialNumber' {
            $SerialNumber = ($SerialNumber -Split ',').Trim()
            foreach ($SN in $SerialNumber) {
                $Request.Query.serialNumber = $SN

                try {
                    $Key = Invoke-ePOwerShellRequest @Request
                } catch {
                    Throw "Failed to find detect recovery key: $($_.Exception.Message)"
                }

                $Result = @{
                    SerialNumber = $SN
                    Key          = $Key
                }

                $Found.Add($Result) | Out-Null
            }
        }
    }

    return $Found
}