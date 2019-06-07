<#
.SYNOPSIS

    Finds available queries on the ePO server

.DESCRIPTION

    Finds all available queries from the ePO server.

.EXAMPLE

    Get-ePOTable

#>

function Get-ePOTable {
    [CmdletBinding()]
    param ()

    begin {
        try {
            $Request = @{
                Name  = 'core.listTables'
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
                Write-Error "Failed to find any ePO queries"
            }

            foreach ($ePOTable in $ePOQueries) {
                Write-Output $ePOTable
            }
        } catch {
            Write-Information $_ -Tags Exception
        }
    }

    end {}
}