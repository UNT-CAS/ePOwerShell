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
                    foreach ($Comp in $Computer) {
                        Write-Debug ('Searching by computer name for: {0}' -f $Comp)
                        if ($Comp -is [ePOComputer]) {
                            Write-Verbose 'Using ePOComputer object'
                            Write-Output $Comp
                        } else {
                            if ($ForceWildcardHandling) {
                                if (-not ($script:AllePOComputers)) {
                                    $Request.Query.searchText = ''
                                    $script:AllePOComputers = Invoke-ePORequest @Request
                                }

                                foreach ($ePOComputer in $script:AllePOComputers) {
                                    if ($ePOComputer.'EPOComputerProperties.ComputerName' -like $Comp) {
                                        $ePOComputerObject = ConvertTo-ePOComputer $ePOComputer
                                        Write-Output $ePOComputerObject
                                    }
                                }
                            } else {
                                $Request.Query.searchText = $Comp
                                $ePOComputers = Invoke-ePORequest @Request

                                foreach ($ePOComputer in $ePOComputers) {
                                    if ($ePOComputer.'EPOComputerProperties.ComputerName' -eq $Comp) {
                                        $ePOComputerObject = ConvertTo-ePOComputer $ePOComputer
                                        Write-Output $ePOComputerObject
                                    }
                                }
                            }
                        }
                    }
                }

                "MACAddress" {
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
                                Write-Error ('MAC Address does not match known format: {0}' -f $Address)
                                continue
                            }
                        }

                        $Request.Query.searchText = $Address
                        $ePOComputers = Invoke-ePORequest @Request

                        foreach ($ePOComputer in $ePOComputers) {
                            $ePOComputerObject = ConvertTo-ePOComputer $ePOComputer
                            Write-Output $ePOComputerObject
                        }
                    }
                }

                "IPAddress" {
                    foreach ($Address in $IPAddress) {
                        $Request.Query.searchText = $Address
                        $ePOComputers = Invoke-ePORequest @Request

                        foreach ($ePOComputer in $ePOComputers) {
                            $ePOComputerObject = ConvertTo-ePOComputer $ePOComputer
                            Write-Output $ePOComputerObject
                        }
                    }
                }

                "Tag" {
                    foreach ($T in $Tag) {
                        if ($T -is [ePOTag]) {
                            $Request.Query.searchText = $T.Name
                        } else {
                            $Request.Query.searchText = $T
                        }
                        $ePOComputers = Invoke-ePORequest @Request

                        foreach ($ePOComputer in $ePOComputers) {
                            $ePOComputerObject = ConvertTo-ePOComputer $ePOComputer
                            Write-Output $ePOComputerObject
                        }
                    }
                }

                "AgentGuid" {
                    foreach ($Guid in $AgentGuid) {
                        $Request.Query.searchText = $Guid
                        $ePOComputers = Invoke-ePORequest @Request

                        foreach ($ePOComputer in $ePOComputers) {
                            $ePOComputerObject = ConvertTo-ePOComputer $ePOComputer
                            Write-Output $ePOComputerObject
                        }
                    }
                }

                "Username" {
                    foreach ($User in $Username) {
                        $Request.Query.searchText = $User
                        $ePOComputers = Invoke-ePORequest @Request

                        foreach ($ePOComputer in $ePOComputers) {
                            $ePOComputerObject = ConvertTo-ePOComputer $ePOComputer
                            Write-Output $ePOComputerObject
                        }
                    }
                }

                "All" {
                    $Request.Query.searchText = ''
                    $ePOComputers = Invoke-ePORequest @Request

                    foreach ($ePOComputer in $ePOComputers) {
                        $ePOComputerObject = ConvertTo-ePOComputer $ePOComputer
                        Write-Output $ePOComputerObject
                    }
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
        }
    }

    end {
        if (Get-Variable 'AllePOComputers' -Scope Script -ErrorAction SilentlyContinue) {
            Remove-Variable -Name 'AllePOComputers' -Scope Script
        }
    }
}

Export-ModuleMember -Function 'Get-ePOComputer' -Alias 'Find-ePOwerShellComputerSystem', 'Find-ePOComputerSystem'