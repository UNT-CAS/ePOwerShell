<#
    .SYNOPSIS
        Finds available predefined queries on the ePO server.

    .DESCRIPTION
        Finds all available queries from the ePO server. Each query is then converted to an ePOQuery object,
        and an array containing all objects will be returned.

    .EXAMPLE
        Get all predefined queries in ePO
        ```powershell
        $Queries = Get-ePOQuery
        ```
#>

function Get-ePOQuery {
    [CmdletBinding()]
    [Alias('Get-ePOwerShellQueries', 'Get-ePOQueries')]
    param ()

    begin {
        try {
            $Request = @{
                Name  = 'core.listQueries'
                Query = @{}
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        try {
            Write-Verbose "Request: $($Request | ConvertTo-Json)"
            if (-not ($ePOQueries = Invoke-ePORequest @Request)) {
                Throw "Failed to find any ePO queries"
            }

            foreach ($ePOQuery in $ePOQueries) {
                $ePOQueryObject = ConvertTo-ePOQuery $ePOQuery
                Write-Output $ePOQueryObject
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {}
}