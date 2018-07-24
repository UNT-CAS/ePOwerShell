function Find-ePOwerShellComputerSystem {
    [CmdletBinding()]
    [Alias("Find-ePOComputerSystem")]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Mandatory = $True, ParameterSetName = 'AgentGuid')]
        [String]
        $AgentGuid,

        [Parameter(Mandatory = $True, ParameterSetName = 'ComputerName')]
        [String]
        $ComputerName,

        [Parameter(Mandatory = $True, ParameterSetName   = 'MACAddress')]
        [String]
        $MACAddress,

        [Parameter(Mandatory = $True, ParameterSetName = 'IPAddress')]
        [String]
        $IPAddress,

        [Parameter(Mandatory = $True, ParameterSetName = 'Tag')]
        [String]
        $Tag,

        [Parameter(Mandatory = $True, ParameterSetName = 'Username')]
        [String]
        $Username,

        [Parameter(Mandatory = $True, ParameterSetName = 'All')]
        [Switch]
        $All,

        [Hashtable]
        $Request = @{
            Name = 'system.find'
            searchText = ''
        }
    )

    begin {}

    process {
        $Response = Invoke-ePOwerShellRequest @Request
        [System.Collections.ArrayList] $Found = @()

        foreach ($item in $Response) {
            switch ($PSBoundParameters.Keys) {
                'ComputerName' {
                    if ($item.'EPOComputerProperties.ComputerName' -ilike $ComputerName) {
                        $Found.Add($item) | Out-Null
                    }
                }
                'MACAddress' {
                    if ($item.'EPOComputerProperties.NetAddress' -ilike $MACAddress) {
                        $Found.Add($item) | Out-Null
                    }
                }
                'IPAddress' {
                    if ($item.'EPOComputerProperties.IPAddress' -ilike $IPAddress) {
                        $Found.Add($item) | Out-Null
                    }
                }
                'Tag' {
                    $tags = $item.'EPOLeafNode.Tags'.Split(',').Trim()
                    foreach ($tag in $tags) {
                        if ($tag -ilike $Tag) {
                            $Found.Add($item) | Out-Null
                            break
                        }
                    }
                }
                'AgentGuid' {
                    if ($item.'EPOLeafNode.AgentGUID' -ilike $AgentGUID) {
                        $Found.Add($item) | Out-Null
                    }
                }
                'Username' {
                    if ($item.'EPOComputerProperties.UserName' -ilike $UserName) {
                        $Found.Add($item) | Out-Null
                    }
                }
                'All' {
                    $Found.Add($item) | Out-Null
                }
                default {
                    $Found.Add($item) | Out-Null
                }
            }
        }
    }

    end {
        return $Found
    }
}