function Find-ePOwerShellComputerSystem {
    [CmdletBinding(DefaultParametersetname = 'ComputerName')]
    [Alias("Find-ePOComputerSystem")]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(ParameterSetName = 'AgentGuid')]
        [String[]]
        $AgentGuid,

        [Parameter(ParameterSetName = 'ComputerName', Position = 1, ValueFromPipeline = $True)]
        [String[]]
        $ComputerName,

        [Parameter(ParameterSetName = 'MACAddress')]
        [String[]]
        $MACAddress,

        [Parameter(ParameterSetName = 'IPAddress')]
        [String[]]
        $IPAddress,

        [Parameter(ParameterSetName = 'Tag')]
        [String[]]
        $Tag,

        [Parameter(ParameterSetName = 'Username')]
        [String[]]
        $Username,

        [Parameter(ParameterSetName = 'All')]
        [Switch]
        $All
    )

    begin {
        $Request = @{
            Name  = 'system.find'
            Query = @{}
        }

        [System.Collections.ArrayList] $Found = @()
    }

    process {
        switch ($PSCmdlet.ParameterSetName) {
            "ComputerName" {
                $ComputerName = $ComputerName.Split(',').Trim()
                foreach ($Computer in $ComputerName) {
                    $CurrentRequest = $Request
                    $CurrentRequest.Query.searchText = $Computer

                    $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                    $Found.Add($ComputerSystems) | Out-Null
                }
            }
            "MACAddress" {
                $MACAddress = $MACAddress.Split(',').Trim()
                foreach ($Address in $MACAddress) {
                    $Address = $Address.ToUpper()

                    switch -Regex ($Address) {
                       '^([0-9a-f]{2}:){5}([0-9a-f]{2})$' {
                            Write-Verbose 'Delimiter: Colons'
                            $Address = $Address.Replace(':', '')
                            break
                        }

                        '^([0-9a-f]{2}-){5}([0-9a-f]{2})$' {
                            Write-Verbose 'Delimiter: Dashs'
                            $Address = $Address.Replace('-', '')
                            break
                        }

                        '^([0-9a-f]{2}\.){5}([0-9a-f]{2})$' {
                            Write-Verbose 'Delimiter: Periods'
                            $Address = $Address.Replace('.', '')
                            break
                        }

                        '^([0-9a-f]{2}\s){5}([0-9a-f]{2})$' {
                            Write-Verbose 'Delimiter: Spaces'
                            $Address = $Address.Replace(' ', '')
                            break
                        }

                        '^([0-9a-f]{12})$' {
                            Write-Verbose 'Delimiter: None'
                            break
                        }

                        default {
                            Throw ('MAC Address does not match known format: {0}' -f $Address)
                        }
                    }

                    $CurrentRequest = $Request
                    $CurrentRequest.Query.searchText = $Address

                    $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                    $Found.Add($ComputerSystems) | Out-Null
                }
            }
            "IPAddress" {
                $IPAddress = $IPAddress.Split(',').Trim()
                foreach ($Address in $IPAddress) {
                    $CurrentRequest = $Request
                    $CurrentRequest.Query.searchText = $Address

                    $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                    $Found.Add($ComputerSystems) | Out-Null
                }
            }
            "Tag" {
                $Tag = $Tag.Split(',').Trim()
                foreach ($T in $Tag) {
                    $CurrentRequest = $Request
                    $CurrentRequest.Query.searchText = $T

                    $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                    $Found.Add($ComputerSystems) | Out-Null
                }
            }
            "AgentGuid" {
                $AgentGuid = $AgentGuid.Split(',').Trim()
                foreach ($Guid in $AgentGuid) {
                    $CurrentRequest = $Request
                    $CurrentRequest.Query.searchText = $Guid

                    $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                    $Found.Add($ComputerSystems) | Out-Null
                }
            }
            "Username" {
                $Username = $Username.Split(',').Trim()
                foreach ($User in $Username) {
                    $CurrentRequest = $Request
                    $CurrentRequest.Query.searchText = $User

                    $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                    $Found.Add($ComputerSystems) | Out-Null
                }
            }
            "All" {
                $CurrentRequest = $Request
                $CurrentRequest.Query.searchText = ''

                $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                $Found.Add($ComputerSystems) | Out-Null
            }
        }
    }

    end {
        if (-not ($Found)) {
            Throw "[Find-ePOwerShellComputerSystem] Failed to find any ePO Systems"
        }
        
        Write-Debug "[Find-ePOwerShellComputerSystem] Results: $($Found | Out-String)"
        return $Found
    }
}