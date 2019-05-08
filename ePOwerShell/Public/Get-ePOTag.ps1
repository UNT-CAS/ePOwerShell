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

function Get-ePOTag {
    [CmdletBinding()]
    [Alias('Find-ePOwerShellTag','Find-ePOTag')]
    [OutputType([System.Collections.ArrayList])]
    param (
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Alias('TagName')]
        $Tag = ''
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
            if ($Tag -is [ePOTag]) {
                Write-Verbose 'Using pipelined ePOTag object'
                [Void] $Found.Add($Tag)
            } else {
                Write-Verbose 'Either not pipelined, or pipeline object is not an ePOTag object'
                $Request = @{
                    Name  = 'system.findTag'
                    Query = @{
                        searchText = $Tag
                    }
                }

                Write-Debug "Request: $($Request | ConvertTo-Json)"
                $ePOTags = Invoke-ePORequest @Request
                
                foreach ($ePOTag in $ePOTags) {
                    if (-not ($Tag) -or ($Tag -eq $ePOTag.tagName)) {
                        $TagObject = [ePOTag]::new($ePOTag.tagName, $ePOTag.tagId, $ePOTag.tagNotes)
                        [Void] $Found.Add($TagObject)
                    }
                }
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

            Write-Debug "Results: $($Found | Out-String)"
            Write-Output $Found
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}
