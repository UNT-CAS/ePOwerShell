<#
.SYNOPSIS

    Finds available queries on the ePO server

.DESCRIPTION

    Finds all available queries from the ePO server.

.EXAMPLE

    Get-ePOwerShellQueries

#>

function Get-ePOwerShellQueries {
    [CmdletBinding()]
    [Alias('Get-ePOQueries')]

    $Request = @{
        Name  = 'core.listQueries'
        Query = @{}
    }

    Write-Debug "[Get-ePOwerShellQueries] Request: $($Request | ConvertTo-Json)"
    if (-not ($ePOQueries = Invoke-ePOwerShellRequest @Request)) {
        Throw "[Get-ePOwerShellQueries] Failed to find any ePO queries"
    }

    Write-Debug "[Get-ePOwerShellQueries] Results: $($ePOQueries | Out-String)"
    return $ePOQueries
}