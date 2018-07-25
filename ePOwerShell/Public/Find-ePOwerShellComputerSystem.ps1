function Find-ePOwerShellComputerSystem {
    [CmdletBinding(DefaultParametersetname = 'ComputerName')]
    [Alias("Find-ePOComputerSystem")]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(ParameterSetName = 'AgentGuid')]
        [String]
        $AgentGuid,

        [Parameter(ParameterSetName = 'ComputerName', Position = 1)]
        [String]
        $ComputerName,

        [Parameter(ParameterSetName = 'MACAddress')]
        [String]
        $MACAddress,

        [Parameter(ParameterSetName = 'IPAddress')]
        [String]
        $IPAddress,

        [Parameter(ParameterSetName = 'Tag')]
        [String]
        $Tag,

        [Parameter(ParameterSetName = 'Username')]
        [String]
        $Username,

        [Parameter(ParameterSetName = 'All')]
        [Switch]
        $All
    )

    begin {
        $Request = @{
            Name  = 'system.find'
            Query = @{
                searchText = ''
            }
        }
    }

    process {
        Write-Debug "[Find-ePOwerShellComputerSystem] Request: $($Request | ConvertTo-Json)"
        $Response = Invoke-ePOwerShellRequest @Request
        [System.Collections.ArrayList] $Found = @()

        foreach ($System in $Response) {
            switch ($PSCmdlet.ParameterSetName) {
                "ComputerName" {
                    if ($System.'EPOComputerProperties.ComputerName' -ieq $ComputerName) {
                        $Found += $System
                    }
                }
                "MACAddress" {
                    if ($System.'EPOComputerProperties.NetAddress' -ieq $MACAddress) {
                        $Found += $System
                    }
                }
                "IPAddress" {
                    if ($System.'EPOComputerProperties.IPAddress' -ieq $IPAddress) {
                        $Found += $System
                    }
                }
                "Tag" {
                    $tags = $System.'EPOLeafNode.Tags'.Split(',').Trim()

                    foreach ($tag in $tags) {
                        if ($tag -ieq $Tag) {
                            $Found += $System
                            break
                        }
                    }
                }
                "AgentGuid" {
                    if ($System.'EPOLeafNode.AgentGUID' -ieq $AgentGUID) {
                        $Found += $System
                    }
                }
                "Username" {
                    if ($System.'EPOComputerProperties.UserName' -ieq $UserName) {
                        $Found += $System
                    }
                }
                "All" {
                    $Found += $System
                }
            }
        }
        Write-Debug "[Find-ePOwerShellComputerSystem] Results: $($Found | Out-String)"
    }

    end {
        return $Found
    }
}