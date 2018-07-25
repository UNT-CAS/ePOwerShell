function Get-ePOwerShellMneRecoveryKey {
    [CmdletBinding(DefaultParametersetname = 'LeafNode')]
    [Alias('Get-ePOMneRecoveryKey')]
    [OutputType([String])]
    param (
        [Parameter(Mandatory = $True, ParameterSetName = 'LeafNode', Position = 1)]
        [String]
        $LeafNodeId,

        [Parameter(Mandatory = $True, ParameterSetName = 'SerialNumber')]
        [String]
        $SerialNumber
    )

    begin {
        $Request = @{
            Name            = 'mne.recoverMachine'
            CustomOutput    = 'terse'
            Query           = @{}
        }

        switch ($PSCmdlet.ParameterSetName) {
            'LeafNode' {
                $Request.Query.Add('epoLeafNodeId', $LeafNodeId) | Out-Null
            }
            'SerialNumber' {
                $Request.Query.Add('serialNumber', $SerialNumber) | Out-Null
            }
        }
    }

    process {
        try {
            $Key = Invoke-ePOwerShellRequest @Request
        } catch {
            Throw "Failed to find detect recovery key: $($_.Exception.Message)"
        }
    }

    end {
        return $Key
    }
}