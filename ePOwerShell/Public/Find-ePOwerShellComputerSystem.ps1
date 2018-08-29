<#
.SYNOPSIS

    Finds available computer system on the ePO server

.DESCRIPTION

    Finds all available computer systems from the ePO server. If a computer system name is specifed, it searches for only
    the one computer system from the server. If a computer system is not specified, then it will return a list of all
    available computer systems on the ePO server. You can search for a computer using the Agent Guid, Computer Name,
    MAC Address, IP Address, Tags, and Usernames.

.PARAMETER AgentGuid

    Specifies the computers Agent Guid to be found on the ePO server

.PARAMETER ComputerName

    Specifies a computer system to be found on the ePO server

.PARAMETER MACAddress

    Specifies the computers MAC Address to be found on the ePO server

.PARAMETER IPAddress

    Specifies the computers IPAddress to be found on the ePO server

.PARAMETER Tag

    Specifies the tag a computer might have applied to be found on the ePO server

.PARAMETER Username

    Specifies the computers Username to be found on the ePO server

.PARAMETER All

    Returns all computers in the ePO server

.EXAMPLE

    Find-ePOwerShellcomputerSystem -All

.EXAMPLE

    Find-ePOwerShellcomputerSystem 'computer1'

.EXAMPLE

    Find-ePOwerShellcomputerSystem 'computer1'

#>

function Find-ePOwerShellComputerSystem {
    [CmdletBinding(DefaultParametersetname = 'ComputerName')]
    [Alias("Find-ePOComputerSystem")]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(ParameterSetName = 'AgentGuid')]
        [String[]]
        $AgentGuid,

        [Parameter(ParameterSetName = 'ComputerName', Position = 0, ValueFromPipeline = $True)]
        [Alias('hostname', 'name', 'computer')]
        [String[]]
        $ComputerName,

        [Parameter(ParameterSetName = 'ComputerName')]
        [Switch]
        $ForceWildcardHandling,

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

                    foreach ($ComputerSystem in $ComputerSystems) {
                        if ($ForceWildcardHandling) {
                            [void]$Found.Add($ComputerSystem)
                        } else {
                            if ($ComputerSystem.'EPOComputerProperties.ComputerName' -eq $Computer) {
                                [void]$Found.Add($ComputerSystem)
                            }
                        }
                    }
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
                    foreach ($System in $ComputerSystems) {
                        [void]$Found.Add($System)
                    }
                }
            }
            "IPAddress" {
                $IPAddress = $IPAddress.Split(',').Trim()
                foreach ($Address in $IPAddress) {
                    $CurrentRequest = $Request
                    $CurrentRequest.Query.searchText = $Address

                    $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                    foreach ($System in $ComputerSystems) {
                        [void]$Found.Add($System)
                    }
                }
            }
            "Tag" {
                $Tag = $Tag.Split(',').Trim()
                foreach ($T in $Tag) {
                    $CurrentRequest = $Request
                    $CurrentRequest.Query.searchText = $T

                    $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                    foreach ($System in $ComputerSystems) {
                        [void]$Found.Add($System)
                    }
                }
            }
            "AgentGuid" {
                $AgentGuid = $AgentGuid.Split(',').Trim()
                foreach ($Guid in $AgentGuid) {
                    $CurrentRequest = $Request
                    $CurrentRequest.Query.searchText = $Guid

                    $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                    foreach ($System in $ComputerSystems) {
                        [void]$Found.Add($System)
                    }
                }
            }
            "Username" {
                $Username = $Username.Split(',').Trim()
                foreach ($User in $Username) {
                    $CurrentRequest = $Request
                    $CurrentRequest.Query.searchText = $User

                    $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                    foreach ($System in $ComputerSystems) {
                        [void]$Found.Add($System)
                    }
                }
            }
            "All" {
                $CurrentRequest = $Request
                $CurrentRequest.Query.searchText = ''

                $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                foreach ($System in $ComputerSystems) {
                    [void]$Found.Add($System)
                }
            }
        }
    }

    end {
        if (-not ($Found)) {
            Throw "[Find-ePOwerShellComputerSystem] Failed to find any ePO Systems"
        }

        [System.Collections.ArrayList] $Return = @()

        foreach ($Computer in $Found) {
            $ComputerItem = [Ordered]@{}

            foreach ($Key in $Computer.PSObject.Properties) {
                [void]$ComputerItem.Add(($Key.Name.Split('.')[1]), $Key.Value)
            }

            [void]$Return.Add(([PSCustomObject]$ComputerItem))
        }
        
        Write-Debug "[Find-ePOwerShellComputerSystem] Results: $($Return | Out-String)"
        return $Return
    }
}