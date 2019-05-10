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
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True, ParameterSetName = 'PremadeQuery')]
        $Query,

        [Parameter(Mandatory = $True, ParameterSetName = 'CustomQuery')]
        [String[]]
        $Select,

        [Parameter(Mandatory = $True, ParameterSetName = 'CustomQuery')]
        [String]
        $Table,

        [Parameter(ParameterSetName = 'CustomQuery')]
        [Parameter(ParameterSetName = 'PremadeQuery')]
        [String]
        $Database
    )

    begin {
        try {
            [System.Collections.ArrayList] $Results = @()
            
            switch ($PSCmdlet.ParameterSetName) {
                'PremadeQuery' {
                    $Request = @{
                        Name  = 'core.executeQuery'
                        Query = @{
                            queryId = ''
                        }
                    }
                }

                'CustomQuery' {
                    $Request = @{
                        Name  = 'core.executeQuery'
                        Query = @{
                            target = $Table
                        }
                    }
                }

                Default {
                    Write-Error 'Failed to determine parameter set' -ErrorAction Stop
                }
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    process {
        try {
            switch ($PSCmdlet.ParameterSetName) {
                'PremadeQuery' {
                    Write-Debug 'Using a premade query'
                    if ($Query -is [ePOQuery]) {
                        Write-Debug 'ePOQuery object specified'
                        $Request.Query.queryId = $Query.ID
                    } elseif ($Query -is [Int32]) {
                        Write-Debug 'Query ID specified'
                        $Request.Query.queryId = $Query
                    } else {
                        Write-Debug 'Query Name specified'
                        if (-not ($ePOQuery = Get-ePOQuery | Where-Object { $_.Name -eq $Query })) {
                            Write-Error ('Failed to find a query for: {0}' -f $Query) -ErrorAction Stop
                        }

                        $Request.Query.queryId = $ePOQuery.ID
                    }
                    
                    if ($Database) {
                        [Void] $Request.Query.Add('database', $Database)
                    }
                }

                'CustomQuery' {
                    $Select = foreach ($Item in $Select) {
                        if ($Item.StartsWith($Table)) {
                            $Item
                        } else {
                            $Table + '.' + $Item
                        }
                    }

                    $Select = '(select ' + ($Select -Join ' ') + ')'
                    [Void] $Request.Query.Add('select', $Select)
                }
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