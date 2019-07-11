<#
    .SYNOPSIS
        Finds available computer systems on the ePO server

    .DESCRIPTION
        Finds all available computer systems from the ePO server. If a computer system name is specifed, it searches for only
        the one computer system from the server. If a computer system is not specified, then it will return a list of all
        available computer systems on the ePO server. You can search for a computer using the Agent Guid, Computer Name,
        MAC Address, IP Address, Tags, and Usernames.

    .EXAMPLE
        $Computer = Get-ePOComputer -All

        Returns all computers in the ePO system

    .EXAMPLE
        $Computer = Get-ePOComputer -ComputerName 'Computer1'

        Returns ePO computer object searching by hostname

    .EXAMPLE
        $Computer = Get-ePOComputer -ComputerName 'Computer*' -ForceWildcardHandling

        Returns ePO computer object searching by hostname with wildcard

    .EXAMPLE
        $Computer = Get-ePOComputer -AgentGuid 5b273b72-977b-4566-9cb4-9af816ac222b

        Returns ePO computer object searching by Agent Guid

    .EXAMPLE
        $Computer = Get-ePOComputer -MacAddress 00-05-9A-3C-7A-00

        Returns ePO computer object searching by MAC Address

    .EXAMPLE
        $Computer = Get-ePOComputer -IPAddress 192.168.32.46

        Returns ePO computer object searching by IP Address

    .EXAMPLE
        $Computer = Get-ePOComputer -Username MyUsername

        Returns ePO computer object searching by Username

    .EXAMPLE
        $Computer = Get-ePOComputer -Tag ePOTag1

        Returns ePO computer objects searching by Tag

    .PARAMETER AgentGuid
        Specifies the computers Agent Guid to be found on the ePO server

    .PARAMETER Computer
        Specifies a computer system to be found on the ePO server

    .PARAMETER ForceWildcardHandling
        Allows for wildcards to be used when searching by computer name

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
#>

function Get-ePOComputer {
    [CmdletBinding(DefaultParameterSetName = 'All')]
    [Alias('Find-ePOwerShellComputerSystem', 'Find-ePOComputerSystem')]
    [OutputType([System.Object[]])]
    param (
        [Parameter(ParameterSetName = 'AgentGuid')]
        $AgentGuid,

        [Parameter(ParameterSetName = 'ComputerName', Position = 1, ValueFromPipeline = $True)]
        [Alias('hostname', 'name', 'computername')]
        $Computer,

        [Parameter(ParameterSetName = 'ComputerName')]
        [Switch]
        $ForceWildcardHandling,

        [Parameter(ParameterSetName = 'MACAddress')]
        $MACAddress,

        [Parameter(ParameterSetName = 'IPAddress')]
        $IPAddress,

        [Parameter(ParameterSetName = 'Tag')]
        $Tag,

        [Parameter(ParameterSetName = 'Username')]
        $Username,

        [Parameter(ParameterSetName = 'All')]
        [Switch]
        $All
    )

    begin {
        try {
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
                Write-Output $Computer
            } else {
                Write-Verbose 'Either not pipelined, or pipeline object is not an ePOComputer object'
                $ePOComputers = Invoke-ePORequest @Request

                foreach ($ePOComputer in $ePOComputers) {
                    $ePOComputerObject = ConvertTo-ePOComputer $ePOComputer
                    if ($PSCmdlet.ParameterSetName -eq 'ComputerName') {
                        if ($ForceWildcardHandling) {
                            Write-Output $ePOComputerObject
                        } elseif ($ePOComputer.'EPOComputerProperties.ComputerName' -eq $Computer) {
                            Write-Output $ePOComputerObject
                        }
                    } else {
                        Write-Output $ePOComputerObject
                    }
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
        }
    }

    end {}
}

Export-ModuleMember -Function 'Get-ePOComputer' -Alias 'Find-ePOwerShellComputerSystem', 'Find-ePOComputerSystem'