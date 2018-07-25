function Find-ePOwerShellGroups {
    [CmdletBinding()]
    [Alias('Find-ePOGroups')]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Position = 1)]
        [String]
        $GroupName
    )

    begin {
        $Request = @{
            Name    = 'system.findGroups'
            Query   = @{
                searchText = $GroupName
            }
        }
    }

    process {
        Write-Debug "[Find-ePOwerShellGroups] Request: $($Request | ConvertTo-Json)"
        $Groups = Invoke-ePOwerShellRequest @Request
    }

    end {
        return $Groups
    }
}