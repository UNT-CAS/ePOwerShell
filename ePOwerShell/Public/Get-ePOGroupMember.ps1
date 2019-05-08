function Get-ePOGroupMember {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $True, Mandatory = $True)]
        $GroupID,

        [Switch]
        $SearchSubgroups
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

            if ($GroupID -is [ePOGroup]) {
                [Void] $Request.Query.Add('groupId', $GroupID.ID)
            } else {
                [Void] $Request.Query.Add('groupId', $GroupID)
            }

            if ($SearchSubgroups) {
                [Void] $Request.Query.Add('searchSubgroups', 'true')
            }

            Write-Debug "Request: $($Request | ConvertTo-Json)"
            $ePOGroupMembers = Invoke-ePOwerShellRequest @Request
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {

    }
}