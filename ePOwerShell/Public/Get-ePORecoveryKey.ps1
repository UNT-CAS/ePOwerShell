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

Class ePORecoveryKey {
    [System.String] $ComputerName
    [System.Object[]] $RecoveryKey
}

function Get-ePORecoveryKey {
    [CmdletBinding(DefaultParametersetname = 'ComputerName')]
    [Alias('Get-ePOwerShellMneRecoveryKey', 'Get-ePOMneRecoveryKey')]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $True, ParameterSetName = 'ComputerName', Position = 0, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias('Name')]
        [String[]]
        $ComputerName,

        [Parameter(Mandatory = $True, ParameterSetName = 'LeafNode')]
        [String[]]
        $LeafNodeId,

        [Parameter(Mandatory = $True, ParameterSetName = 'SerialNumber')]
        [String[]]
        $SerialNumber
    )

    begin {
        $TableName = 'RecoveryKeys'
        $Table = New-Object System.Data.DataTable $TableName
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            'ComputerName' {
                if (-not ($Table.Columns | ? { $_.ColumnName -eq 'ComputerName' })) {
                    $Column1 = New-Object System.Data.DataColumn 'ComputerName', ([String])
                    [void]$Table.Columns.Add($Column1)
                }

                if (-not ($Table.Columns | ? { $_.ColumnName -eq 'RecoveryKey' })) {
                    $Column2 = New-Object System.Data.DataColumn 'RecoveryKey', ([String])
                    [void]$Table.Columns.Add($Column2)
                }
                

                foreach ($Computer in $ComputerName) {
                    try {
                        $ComputerInformation = Find-ePOwerShellComputerSystem -ComputerName $Computer
                    } catch {
                        Write-Warning ('Failed to find comptuer system in ePO: {0}' -f $Computer)
                        continue
                    }

                    $Request = @{
                        Name     = 'mne.recoverMachine'
                        PassThru = $True
                        Query    = @{
                            epoLeafNodeId = $ComputerInformation.ParentID
                        }
                    }

                    try {
                        $Key = Invoke-ePOwerShellRequest @Request
                    } catch {
                        Write-Warning ('Failed to find detect recovery key for computer: {0}' -f $ComputerInformation.ComputerName)
                        continue
                    }

                    $Row = $Table.NewRow()
                    $Row.ComputerName = $ComputerInformation.ComputerName
                    $Row.RecoveryKey = $Key
                    [void]$Table.Rows.Add($Row)
                }
            }
            'LeafNode' {
                # if (-not ($Table.Columns | ? { $_.ColumnName -eq 'LeafNode' })) {
                    $Column1 = New-Object System.Data.DataColumn 'LeafNode', ([String])
                    [void]$Table.Columns.Add($Column1)
                # }

                # if (-not ($Table.Columns | ? { $_.ColumnName -eq 'RecoveryKey' })) {
                    $Column2 = New-Object System.Data.DataColumn 'RecoveryKey', ([String])
                    [void]$Table.Columns.Add($Column2)
                # }

                foreach ($LeafNode in $LeafNodeId) {
                    $Request = @{
                        Name     = 'mne.recoverMachine'
                        PassThru = $True
                        Query    = @{
                            epoLeafNodeId = $LeafNode
                        }
                    }

                    try {
                        $Key = Invoke-ePOwerShellRequest @Request
                    } catch {
                        Throw "Failed to find detect recovery key: $($_.Exception.Message)"
                    }

                    $Row = $Table.NewRow()
                    $Row.LeafNode = $LeafNode
                    $Row.RecoveryKey = $Key
                    [void]$Table.Rows.Add($Row)
                }
            }
            'SerialNumber' {
                # if (-not ($Table.Columns | ? { $_.ColumnName -eq 'SerialNumber' })) {
                    $Column1 = New-Object System.Data.DataColumn 'SerialNumber', ([String])
                    [void]$Table.Columns.Add($Column1)
                # }

                # if (-not ($Table.Columns | ? { $_.ColumnName -eq 'RecoveryKey' })) {
                    $Column2 = New-Object System.Data.DataColumn 'RecoveryKey', ([String])
                    [void]$Table.Columns.Add($Column2)
                # }

                foreach ($SN in $SerialNumber) {
                    $Request = @{
                        Name     = 'mne.recoverMachine'
                        PassThru = $True
                        Query    = @{
                            serialNumber = $SN
                        }
                    }

                    try {
                        $Key = Invoke-ePOwerShellRequest @Request
                    } catch {
                        Throw "Failed to find detect recovery key: $($_.Exception.Message)"
                    }

                    $Row = $Table.NewRow()
                    $Row.SerialNumber = $SN
                    $Row.RecoveryKey = $Key
                    [void]$Table.Rows.Add($Row)
                }
            }
        }
    }

    end {
        return $Table
    }
}