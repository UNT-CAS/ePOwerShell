<#
.SYNOPSIS

    Finds available queries on the ePO server

.DESCRIPTION

    Finds all available queries from the ePO server.

.EXAMPLE

    Get-ePOQuery

#>

function Get-ePOQuery {
    [CmdletBinding()]
    [Alias('Get-ePOwerShellQueries', 'Get-ePOQueries')]
    param ()

    begin {
        try {
            [System.Collections.ArrayList] $Found = @()

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
                [Void] $Found.Add((ConvertTo-ePOQuery $ePOQuery))
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {
        try {
            Write-Verbose "Results: $($Found | Out-String)"
            Write-Output $Found
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}