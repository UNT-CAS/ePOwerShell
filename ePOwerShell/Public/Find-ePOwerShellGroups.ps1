function Find-ePOwerShellGroups {
    [CmdletBinding()]
    [Alias('Find-ePOGroups')]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Position = 1)]
        [String]
        $GroupName,

        [Switch]
        $PassThru
    )

    begin {
        $Request = @{
            Name    = 'system.findGroups'
            Query   = @{
                searchText = $GroupName
            }
            PassThru = $PassThru
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