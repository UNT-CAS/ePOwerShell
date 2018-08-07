function Find-ePOwerShellGroups {
    [CmdletBinding()]
    [Alias('Find-ePOGroups')]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Position = 1, ValueFromPipeline = $True)]
        [String[]]
        $GroupName,

        [Switch]
        $PassThru
    )

    begin {
        [System.Collections.ArrayList] $Found = @()

        if (-not ($GroupName)) {
            $GroupName = ''
        }
    }

    process {
        foreach ($Group in $GroupName) {
            $Request = @{
                Name     = 'system.findGroups'
                Query    = @{
                    searchText = $Group
                }
                PassThru = $PassThru
            }

            Write-Debug "[Find-ePOwerShellGroups] Request: $($Request | ConvertTo-Json)"
            $ePOGroups = Invoke-ePOwerShellRequest @Request

            if ($PassThru) {
                $Found.Add($ePOGroups) | Out-Null
            } else {
                $Found.Add(($ePOGroups | ConvertFrom-Json)) | Out-Null
            }
        }
    }

    end {
        return $Found
    }
}