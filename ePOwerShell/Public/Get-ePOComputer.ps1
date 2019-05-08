<#
    .SYNOPSIS
        Finds available computer system on the ePO server

    .DESCRIPTION
        Finds all available computer systems from the ePO server. If a computer system name is specifed, it searches for only
        the one computer system from the server. If a computer system is not specified, then it will return a list of all
        available computer systems on the ePO server. You can search for a computer using the Agent Guid, Computer Name,
        MAC Address, IP Address, Tags, and Usernames.

    .EXAMPLE
        Returns all computers in the ePO system
        `Get-ePOComputer -All`

    .EXAMPLE
        Returns ePO computer object searching by hostname
        `Get-ePOComputer -ComputerName 'Computer1'`

    .EXAMPLE
        Returns ePO computer object searching by hostname with wildcard
        `Get-ePOComputer -ComputerName 'Computer*' -ForceWildcardHandling`

    .EXAMPLE
        Returns ePO computer object searching by Agent Guid
        `Get-ePOComputer -AgentGuid 5b273b72-977b-4566-9cb4-9af816ac222b`

    .EXAMPLE
        Returns ePO computer object searching by MAC Address
        `Get-ePOComputer -MacAddress 00-05-9A-3C-7A-00`

    .EXAMPLE
        Returns ePO computer object searching by IP Address
        `Get-ePOComputer -MacAddress 192.168.32.46`

    .EXAMPLE
        Returns ePO computer object searching by Username
        `Get-ePOComputer -Username MyUsername`

    .EXAMPLE
        Returns ePO computer objects searching by Tag
        `Get-ePOComputer -Tag ePOTag1`
#>

function Get-ePOComputer {
    [CmdletBinding()]
    [Alias('Find-ePOwerShellComputerSystem', 'Find-ePOComputerSystem')]
    [OutputType([System.Object[]])]
    param (
        <#
            .PARAMETER AgentGuid
                Specifies the computers Agent Guid to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'AgentGuid')]
        [String[]]
        $AgentGuid,

        <#
            .PARAMETER ComputerName
                Specifies a computer system to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'ComputerName', Position = 0, ValueFromPipeline = $True)]
        [Alias('hostname', 'name', 'computer')]
        [String[]]
        $ComputerName,

        <#
            .PARAMETER ForceWildcardHandling
                Allows for wildcards to be used when searching by computer name
        #>
        [Parameter(ParameterSetName = 'ComputerName')]
        [Switch]
        $ForceWildcardHandling,

        <#
            .PARAMETER MACAddress
                Specifies the computers MAC Address to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'MACAddress')]
        [String[]]
        $MACAddress,

        <#
            .PARAMETER IPAddress
                Specifies the computers IPAddress to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'IPAddress')]
        [String[]]
        $IPAddress,

        <#
            .PARAMETER Tag
                Specifies the tag a computer might have applied to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'Tag')]
        [String[]]
        $Tag,

        <#
            .PARAMETER Username
                Specifies the computers Username to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'Username')]
        [String[]]
        $Username,

        <#
            .PARAMETER All
                Returns all computers in the ePO server
        #>
        [Parameter(ParameterSetName = 'All')]
        [Switch]
        $All
    )

    begin {
        try {
            $Request = @{
                Name  = 'system.find'
                Query = @{}
            }

            [System.Collections.ArrayList] $Found = @()
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
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
                            [Void] $Found.Add($ComputerSystem)
                        } else {
                            if ($ComputerSystem.'EPOComputerProperties.ComputerName' -eq $Computer) {
                                [Void] $Found.Add($ComputerSystem)
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
                        [Void] $Found.Add($System)
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
                        [Void] $Found.Add($System)
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
                        [Void] $Found.Add($System)
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
                        [Void] $Found.Add($System)
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
                        [Void] $Found.Add($System)
                    }
                }
            }
            "All" {
                $CurrentRequest = $Request
                $CurrentRequest.Query.searchText = ''

                $ComputerSystems = Invoke-ePOwerShellRequest @CurrentRequest
                foreach ($System in $ComputerSystems) {
                    [Void] $Found.Add($System)
                }
            }
            default {
                Throw "Invalid option. Please specify a parameter."
            }
        }
    }

    end {
        try {
            if (-not ($Found)) {
                Write-Error "Failed to find any ePO Systems" -ErrorAction Stop
            }

            [System.Collections.ArrayList] $Return = @()

            foreach ($Computer in $Found) {
                $ComputerItem = [Ordered]@{}

                foreach ($Key in $Computer.PSObject.Properties) {
                    [Void] $ComputerItem.Add(($Key.Name.Split('.')[1]), $Key.Value)
                }

                [Void] $Return.Add(([PSCustomObject]$ComputerItem))
            }

            Write-Verbose "[Get-ePOComputer] Results: $($Return | Format-Table)"

            return $Return
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}