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