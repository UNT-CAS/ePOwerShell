<#
.SYNOPSIS

    Finds available groups on the ePO server

.DESCRIPTION

    Finds all available groups from the ePO server. If a group name is specifed, it searches for only
    the one group from the server. If a group is not specified, then it will return a list of all
    available groups on the ePO server.

.PARAMETER GroupName

    Specifies a group to be found on the ePO server

.PARAMETER PassThru

    If called, function returns the raw content from the ePO server

.EXAMPLE

    Find-ePOwerShellgroup

.EXAMPLE

    Find-ePOwerShellgroup 'group1'

.EXAMPLE

    Find-ePOwerShellgroup 'group1' -PassThru

#>

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