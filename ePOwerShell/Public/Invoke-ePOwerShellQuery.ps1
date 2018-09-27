<#
.SYNOPSIS

    Runs a query that's available on the ePO server.

.DESCRIPTION

    Based off the Query Name or ID, runs the query and returns the output.

.EXAMPLE

    Invoke-ePOwerShellQuery

#>

function Invoke-ePOwerShellQuery {
    [CmdletBinding()]
    [Alias('Invoke-ePOQuery')]
    param (
        [Parameter(Mandatory = $True, ParameterSetName = 'QueryId', Position = 0, ValueFromPipeline = $True, ValueFromPipelineByPropertyName = $True)]
        [Alias('id')]
        [String[]]
        $QueryId,

        [Parameter(Mandatory = $True, ParameterSetName = 'QueryName')]
        [String[]]
        $QueryName,

        [Parameter(Position = 1)]
        [String]
        $Database
    )

    begin {
        [System.Collections.ArrayList] $Results = @()
        [System.Collections.ArrayList] $IDs = @()

        switch ($PSCmdlet.ParameterSetName) {
            'QueryId' {
                $QueryId | % {
                    [void]$IDs.Add($_)
                }
            }
            'QueryName' {
                $Queries = Get-ePOwerShellQueries
                
                foreach ($Query in $QueryName) {
                    [void]$IDs.Add((($Queries | ? { $_.Name -eq $Query }).id))
                }
            }
        }
    }

    process {
        foreach ($ID in $IDs) {
            $Request = @{
                Name  = 'core.executeQuery'
                Query = @{
                    queryId = $ID
                }
            }
        
            if ($Database) {
                [void]$Request.Query.Add('database', $Database)
            }
        
            Write-Debug "[Invoke-ePOwerShellQuery] Request: $($Request | ConvertTo-Json)"
            if (-not ($QueryResults = Invoke-ePOwerShellRequest @Request)) {
                Throw "[Invoke-ePOwerShellQuery] Failed to find any ePO query results"
            }
    
            Write-Debug "[Invoke-ePOwerShellQuery] Results: $($QueryResults | Out-String)"
            [void]$Results.Add($QueryResults)
        }
    }

    end {
        return $Results
    }
}