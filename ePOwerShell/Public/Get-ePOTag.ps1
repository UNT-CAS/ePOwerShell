<#
    .SYNOPSIS
        Finds available tags on the ePO server

    .DESCRIPTION
        Finds all available tags from the ePO server. If a tag name is specifed, it searches for only
        the one tag from the server. If a tag is not specified, then it will return an array of ePOTag
        objects from the ePO server. Each tag contains an ID, Name, and Description.

    .EXAMPLE
        Get all tags from the ePO server
        ```powershell
        $Tags = Get-ePOTag
        ```

    .EXAMPLE
        Get a single tag from the ePO server
        ```powershell
        $Tag = Get-ePOTag 'Tag1'
        ```
#>

function Get-ePOTag {
    [CmdletBinding()]
    [Alias('Find-ePOwerShellTag','Find-ePOTag')]
    [OutputType([System.Object[]])]
    param (
        <#
            .PARAMETER Tag
                This parameter is used to request a specific tag. This can be provided as:

                    * An ePOTag object
                    * A tag name

                This value can be passed in from the pipeline.
        #>
        [Parameter(Position = 0, ValueFromPipeline = $True)]
        [Alias('TagName')]
        $Tag = ''
    )

    begin {}

    process {
        try {
            if ($Tag -is [ePOTag]) {
                Write-Verbose 'Using pipelined ePOTag object'
                Write-Output $Tag
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
                        Write-Output $TagObject
                    }
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
        }
    }

    end {}
}

Export-ModuleMember -Function 'Get-ePOTag' -Alias 'Find-ePOwerShellTag','Find-ePOTag'