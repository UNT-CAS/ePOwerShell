function Get-ePOwerShellMneRecoveryKey {
    [CmdletBinding(DefaultParametersetname = 'LeafNode')]
    [Alias('Get-ePOMneRecoveryKey')]
    [OutputType([String])]
    param (
        [Parameter(Mandatory = $True, ParameterSetName = 'LeafNode', Position = 1, ValueFromPipeline = $True)]
        [String[]]
        $LeafNodeId,

        [Parameter(Mandatory = $True, ParameterSetName = 'SerialNumber')]
        [String[]]
        $SerialNumber
    )

    begin {
        $Request = @{
            Name        = 'mne.recoverMachine'
            PassThru    = $True
            Query       = @{}
        }

        [System.Collections.ArrayList] $Found = @()
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'LeafNode' {
                foreach ($LeafNode in $LeafNodeId) {
                    $Request.Query.epoLeafNodeId = $LeafNode
                    $Result = @{
                        'LeafNodeId' = $LeafNode
                    }

                    try {
                        $Key = Invoke-ePOwerShellRequest @Request
                    } catch {
                        Write-Error "Failed to find detect recovery key: $($_.Exception.Message)"
                    }

                    $Result.Add('Key', $Key) | Out-Null
                    $Found.Add($Result) | Out-Null
                }
            }
            'SerialNumber' {
                foreach ($SN in $SerialNumber) {
                    $Request.Query.serialNumber = $SN
                    $Result = @{
                        'SerialNumber' = $SN
                    }

                    try {
                        $Key = Invoke-ePOwerShellRequest @Request
                    } catch {
                        Write-Error "Failed to find detect recovery key: $($_.Exception.Message)"
                    }

                    $Result.Add('Key', $Key) | Out-Null
                    $Found.Add($Result) | Out-Null
                }
            }
        }
    }

    end {
        return ($Found | % { [PSCustomObject]$_ })
    }
}