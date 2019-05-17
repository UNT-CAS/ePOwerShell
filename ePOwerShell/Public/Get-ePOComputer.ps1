<#
    .SYNOPSIS
        Finds available computer systems on the ePO server

    .DESCRIPTION
        Finds all available computer systems from the ePO server. If a computer system name is specifed, it searches for only
        the one computer system from the server. If a computer system is not specified, then it will return a list of all
        available computer systems on the ePO server. You can search for a computer using the Agent Guid, Computer Name,
        MAC Address, IP Address, Tags, and Usernames.

    .EXAMPLE
        Returns all computers in the ePO system
        ```powershell
        $Computer = Get-ePOComputer -All
        ```

    .EXAMPLE
        Returns ePO computer object searching by hostname
        ```powershell
        $Computer = Get-ePOComputer -ComputerName 'Computer1'
        ```

    .EXAMPLE
        Returns ePO computer object searching by hostname with wildcard
        ```powershell
        $Computer = Get-ePOComputer -ComputerName 'Computer*' -ForceWildcardHandling
        ```

    .EXAMPLE
        Returns ePO computer object searching by Agent Guid
        ```powershell
        $Computer = Get-ePOComputer -AgentGuid 5b273b72-977b-4566-9cb4-9af816ac222b
        ```

    .EXAMPLE
        Returns ePO computer object searching by MAC Address
        ```powershell
        $Computer = Get-ePOComputer -MacAddress 00-05-9A-3C-7A-00
        ```

    .EXAMPLE
        Returns ePO computer object searching by IP Address
        ```powershell
        $Computer = Get-ePOComputer -IPAddress 192.168.32.46
        ```

    .EXAMPLE
        Returns ePO computer object searching by Username
        ```powershell
        $Computer = Get-ePOComputer -Username MyUsername
        ```

    .EXAMPLE
        Returns ePO computer objects searching by Tag
        ```powershell
        $Computer = Get-ePOComputer -Tag ePOTag1
        ```
#>

function Get-ePOComputer {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [Alias('Find-ePOwerShellComputerSystem', 'Find-ePOComputerSystem')]
    [OutputType([System.Object[]])]
    param (
        <#
            .PARAMETER AgentGuid
                Specifies the computers Agent Guid to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'AgentGuid')]
        $AgentGuid,

        <#
            .PARAMETER Computer
                Specifies a computer system to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'ComputerName', Position = 1, ValueFromPipeline = $True)]
        [Alias('hostname', 'name', 'computername')]
        $Computer,

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
        $MACAddress,

        <#
            .PARAMETER IPAddress
                Specifies the computers IPAddress to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'IPAddress')]
        $IPAddress,

        <#
            .PARAMETER Tag
                Specifies the tag a computer might have applied to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'Tag')]
        $Tag,

        <#
            .PARAMETER Username
                Specifies the computers Username to be found on the ePO server
        #>
        [Parameter(ParameterSetName = 'Username')]
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
            [System.Collections.ArrayList] $Found = @()

            $Request = @{
                Name  = 'system.find'
                Query = @{
                    searchText = ''
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                "ComputerName" {
                    $Request.Query.searchText = $Computer
                }

                "MACAddress" {
                    $MACAddress = $MACAddress.ToUpper()

                    switch -Regex ($MACAddress) {
                        '^([0-9a-f]{2}:){5}([0-9a-f]{2})$' {
                            Write-Verbose 'Delimiter: Colons'
                            $MACAddress = $MACAddress.Replace(':', '')
                            break
                        }

                        '^([0-9a-f]{2}-){5}([0-9a-f]{2})$' {
                            Write-Verbose 'Delimiter: Dashs'
                            $MACAddress = $MACAddress.Replace('-', '')
                            break
                        }

                        '^([0-9a-f]{2}\.){5}([0-9a-f]{2})$' {
                            Write-Verbose 'Delimiter: Periods'
                            $MACAddress = $MACAddress.Replace('.', '')
                            break
                        }

                        '^([0-9a-f]{2}\s){5}([0-9a-f]{2})$' {
                            Write-Verbose 'Delimiter: Spaces'
                            $MACAddress = $MACAddress.Replace(' ', '')
                            break
                        }

                        '^([0-9a-f]{12})$' {
                            Write-Verbose 'Delimiter: None'
                            break
                        }

                        default {
                            Throw ('MAC Address does not match known format: {0}' -f $MACAddress)
                        }
                    }

                    $Request.Query.searchText = $MACAddress
                }

                "IPAddress" {
                    $Request.Query.searchText = $IPAddress
                }

                "Tag" {
                    $Request.Query.searchText = $Tag
                }

                "AgentGuid" {
                    $Request.Query.searchText = $AgentGuid
                }

                "Username" {
                    $Request.Query.searchText = $Username
                }

                "All" {
                    $Request.Query.searchText = ''
                }
            }

            if ($PSCmdlet.ParameterSetName -eq 'ComputerName' -and $Computer -is [ePOComputer]) {
                Write-Verbose 'Using pipelined ePOComputer object'
                [Void] $Found.Add($Computer)
            } else {
                Write-Verbose 'Either not pipelined, or pipeline object is not an ePOComputer object'
                $ePOComputers = Invoke-ePORequest @Request

                foreach ($ePOComputer in $ePOComputers) {
                    if ($PSCmdlet.ParameterSetName -eq 'ComputerName') {
                        if ($ForceWildcardHandling) {
                            [Void] $Found.Add((ConvertTo-ePOComputer $ePOComputer))
                        } elseif ($ePOComputer.'EPOComputerProperties.ComputerName' -eq $Computer) {
                            [Void] $Found.Add((ConvertTo-ePOComputer $ePOComputer))
                        }
                    } else {
                        [Void] $Found.Add((ConvertTo-ePOComputer $ePOComputer))
                    }
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {
        try {
            if (-not ($Found)) {
                Write-Error "Failed to find any ePO Systems" -ErrorAction Stop
            }

            Write-Verbose "Results: $($Found | ConvertTo-Json)"

            Write-Output $Found
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}