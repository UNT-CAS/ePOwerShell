<#
    .SYNOPSIS
        Returns members of a specified ePO group

    .DESCRIPTION
        This function returns an array of ePOComputer objects for each computer in the specified ePO group. If the `$Recurse`
        parameter is specified, then all subgroups are included in the search as well.

    .EXAMPLE
        Get group members of a single group
        ```powershell
        $Group = Get-ePOGroup -Group 'Group1'
        $GroupMembers = Get-ePOGroupMember -Group $Group
        ```

    .EXAMPLE
        Get group members from a pipeline
        ```powershell
        $GroupMembers = Get-ePOGroup -Group 'Group1' | Get-ePOGroupMember
        ```

    .EXAMPLE
        Recursively get group members from a pipeline
        ```powershell
        $GroupMembers = Get-ePOGroup -Group 'Group1' | Get-ePOGroupMember -Recurse
        ```
#>

function Get-ePOGroupMember {
    [CmdletBinding()]
    param (
        <#
            .PARAMETER Group
                Specifies the group we want to search for group members. This parameter can be provided as either:

                    * An ePOGroup object
                    * A group name

                This parameter can be passed in from the pipeline
        #>
        [Parameter(Position = 0, ValueFromPipeline = $True, Mandatory = $True)]
        $Group,

        <#
            .PARAMETER Recurse
                Include members in all subgroups
        #>
        [Switch]
        $Recurse
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
            $Request = @{
                Name  = 'epogroup.findSystems'
                Query = @{}
            }

            if ($Group -is [ePOGroup]) {
                [Void] $Request.Query.Add('groupId', $GroupID.ID)
            } else {
                [Void] $Request.Query.Add('groupId', $Group)
            }

            if ($Recurse) {
                [Void] $Request.Query.Add('searchSubgroups', 'true')
            }

            Write-Debug "Request: $($Request | ConvertTo-Json)"
            $ePOGroupMembers = Invoke-ePORequest @Request

            foreach ($ePOGroupMember in $ePOGroupMembers) {
                [Void] $Found.Add((ConvertTo-ePOComputer $ePOGroupMember))
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
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