function Find-ePOwerShellTag {
    [CmdletBinding()]
    [Alias('Find-ePOTag')]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Position = 1, ValueFromPipeline = $True)]
        [String[]]
        $Tag
    )

    begin {
        [System.Collections.ArrayList] $Found = @()

        if (-not ($Tag)) {
            $Tag = ''
        }
    }

    process {
        foreach ($T in $Tag) {
            $Request = @{
                Name     = 'system.findTag'
                Query    = @{
                    searchText = $T
                }
            }

            Write-Debug "[Find-ePOwerShellGroups] Request: $($Request | ConvertTo-Json)"
            $ePOGroups = Invoke-ePOwerShellRequest @Request

            $Found.Add($ePOGroups) | Out-Null
        }
    }

    end {
        if (-not ($Found)) {
            Throw "[Find-ePOwerShellTag] Failed to find any ePO Tags"
        }

        Write-Debug "[Find-ePOwerShellTag] Results: $($Found | Out-String)"
        return $Found
    }
}