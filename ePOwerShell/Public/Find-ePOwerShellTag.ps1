<#
.SYNOPSIS

    Finds available tags on the ePO server

.DESCRIPTION

    Finds all available tags from the ePO server. If a tag name is specifed, it searches for only
    the one tag from the server. If a tag is not specified, then it will return a list of all
    available tags on the ePO server. Each tag contains a Tag ID, Tag Name, and Description.

.PARAMETER Tag

    Specifies a tag to be found on the ePO server

.EXAMPLE

    Find-ePOwerShellTag

.EXAMPLE

    Find-ePOwerShellTag 'Tag1'

#>

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