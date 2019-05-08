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

    Get-ePOTag

.EXAMPLE

    Get-ePOTag 'Tag1'

#>

Class ePOTag {
    [System.String] $Name
    [System.Int32]  $ID
    [System.String] $Description
}

function Get-ePOTag {
    [CmdletBinding()]
    [Alias('Find-ePOwerShellTag','Find-ePOTag')]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        $TagName = ''
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
            $TagObject = [ePOTag]::new()

            $Request = @{
                Name  = 'system.findTag'
                Query = @{}
            }

            if ($Tag -is [ePOTag]) {
                [Void] $Request.Query.Add('searchText', $Tag.Name)
            } else {
                [Void] $Request.Query.Add('searchText', $Tag)
            }

            Write-Debug "Request: $($Request | ConvertTo-Json)"
            $ePOTags = Invoke-ePORequest @Request

            foreach ($ePOTag in $ePOTags) {
                $TagObject.Name = $ePOTag.tagName
                $TagObject.ID = $ePOTag.tagId
                $TagObject.Description = $ePOTag.tagNotes
                [Void] $Found.Add($TagObject)
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {
        try {
            if (-not ($Found)) {
                Write-Error 'Failed to find any ePO Tags' -ErrorAction Stop
            }

            Write-Debug "[Get-ePOTag] Results: $($Found | Out-String)"
            Write-Output $Found
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}
