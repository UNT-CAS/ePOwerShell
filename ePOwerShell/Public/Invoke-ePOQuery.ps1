<#
.SYNOPSIS

    Runs a query that's available on the ePO server.

.DESCRIPTION

    Based off the Query Name or ID, runs the query and returns the output.

.EXAMPLE

    Invoke-ePOQuery

#>

function Invoke-ePOQuery {
    [CmdletBinding()]
    [Alias('Invoke-ePOwerShellQuery', 'Invoke-ePOQuery')]
    param (
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True)]
        $Query,

        [Parameter(Position = 1)]
        [String]
        $Database
    )

    begin {
        try {
            [System.Collections.ArrayList] $Results = @()
            
            $Request = @{
                Name  = 'core.executeQuery'
                Query = @{
                    queryId = ''
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        try {
            if ($Query -is [ePOQuery]) {
                $Request.Query.queryId = $Query.ID
            } elseif ($Query -is [Int32]) {
                $Request.Query.queryId = $Query
            } else {
                if (-not ($ePOQuery = Get-ePOQuery | Where-Object { $_.Name -eq $Query })) {
                    Write-Error ('Failed to find a query for: {0}' -f $Query)
                }

                $Request.Query.queryId = $ePOQuery.ID
            }
            
            if ($Database) {
                [Void] $Request.Query.Add('database', $Database)
            }
        
            Write-Debug "Request: $($Request | ConvertTo-Json)"
            if (-not ($QueryResults = Invoke-ePORequest @Request)) {
                Throw "Failed to find any ePO query results"
            }
    
            Write-Debug "Results: $($QueryResults | Out-String)"
            [Void] $Results.Add($QueryResults)
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {
        try {
            Write-Output $Results
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}