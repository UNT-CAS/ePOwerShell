<#
    .SYNOPSIS
        Returns members of a specified ePO group

    .DESCRIPTION
        This function returns an array of ePOComputer objects for each computer in the specified ePO group. If the `$Recurse`
        parameter is specified, then all subgroups are included in the search as well.

    .EXAMPLE
        $GroupMembers = Get-ePOGroupMember -Group $Group

        Get group members of a single group

    .EXAMPLE
        $GroupMembers = Get-ePOGroup -Group 'Group1' | Get-ePOGroupMember

        Get group members from a pipeline

    .EXAMPLE
        $GroupMembers = Get-ePOGroup -Group 'Group1' | Get-ePOGroupMember -Recurse

        Recursively get group members from a pipeline

    .PARAMETER Group
        Specifies the group we want to search for group members. This parameter can be provided as either:

            * An ePOGroup object
            * A group name

        This parameter can be passed in from the pipeline

    .PARAMETER Recurse
        Include members in all subgroups
#>

function Get-ePOGroupMember {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $True, Mandatory = $True)]
        $Group,

        [Switch]
        $Recurse
    )

    begin {
        if ($Group) {
            $Group = $Group.Split(',').Trim()
        }
    }

    process {
        try {
            foreach ($GroupItem in $Group) {
                $Request = @{
                    Name  = 'epogroup.findSystems'
                    Query = @{}
                }

                if ($GroupItem -is [ePOGroup]) {
                    [Void] $Request.Query.Add('groupId', $GroupItem.ID)
                } else {
                    [Void] $Request.Query.Add('groupId', $GroupItem)
                }

                if ($Recurse) {
                    [Void] $Request.Query.Add('searchSubgroups', 'true')
                }

                Write-Debug "Request: $($Request | ConvertTo-Json)"
                $ePOGroupMembers = Invoke-ePORequest @Request

                foreach ($ePOGroupMember in $ePOGroupMembers) {
                    $ePOGroupMemberObject = ConvertTo-ePOComputer $ePOGroupMember
                    Write-Output $ePOGroupMemberObject
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {}
}

Export-ModuleMember -Function 'Get-ePOGroupMember'