<#
.SYNOPSIS

    Finds available groups on the ePO server

.DESCRIPTION

    Finds all available groups from the ePO server. If a group name is specifed, it searches for only
    the one group from the server. If a group is not specified, then it will return a list of all
    available groups on the ePO server.

.EXAMPLE
    Returns array of ePOGroup objects containing group information
    Find-ePOGroup

.EXAMPLE
    Returns array of ePOGroup objects containing requested group information with matching group name
    Find-ePOGroup 'Group1'

.EXAMPLE
    Returns array of ePOGroup objects containing requested group information with matching group name by wildcard
    Find-ePOGroup 'Group*' -ForceWildcardHandling
#>

function Get-ePOGroup {
    [CmdletBinding()]
    [Alias('Find-ePOwerShellGroups','Find-ePOGroups')]
    [OutputType([System.Object[]])]
    param (
        <#
            .PARAMETER Group
                Specifies a group name to be found on the ePO server
        #>
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Alias('GroupName')]
        $Group = '',

        <#
            .PARAMETER ForceWildcardHandling
                Allows for wildcards to be used when searching by group name
        #>
        [Switch]
        $ForceWildcardHandling
    )

    begin {
        try {
            [System.Collections.ArrayList] $Found = @()
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        try {
            if ($Group -is [ePOGroup]) {
                [Void] $Found.Add($Group)
            } else {
                $Request = @{
                    Name  = 'system.findGroups'
                    Query = @{
                        searchText = $Group
                    }
                }
    
                Write-Debug "Request: $($Request | ConvertTo-Json)"
                $ePOGroups = Invoke-ePORequest @Request
    
                foreach ($ePOGroup in $ePOGroups) {
                    $GroupObject = [ePOGroup]::new()
                    $GroupObject.Name = $ePOGroup.groupPath
                    $GroupObject.ID   = $ePOGroup.groupId
                    [Void] $Found.Add($GroupObject)
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw
        }
    }

    end {
        try {
            Write-Output $Found
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}
