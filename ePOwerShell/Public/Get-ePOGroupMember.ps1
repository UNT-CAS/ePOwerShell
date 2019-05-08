function Get-ePOGroupMember {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $True, Mandatory = $True)]
        $Group,

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

            if ($Group -is [ePOGroup]) {
                [Void] $Request.Query.Add('groupId', $GroupID.ID)
            } else {
                [Void] $Request.Query.Add('groupId', $Group)
            }

            if ($SearchSubgroups) {
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