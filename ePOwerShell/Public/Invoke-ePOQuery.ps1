<#
.SYNOPSIS
    Either runs a predefined query or a custom query against the ePO server

.DESCRIPTION
    Based off the Query Name or ID, runs the query and returns the output.

.EXAMPLE
    Run a predefined query saved on the ePO server:
    ```powershell
    $Query = Get-ePOQuery
    $Query = $Query | Where-Object { $_.Name -eq 'My Awesome Query' }
    $Results = Invoke-ePOQuery -Query $Query
    ```
#>

function Invoke-ePOQuery {
    [CmdletBinding()]
    [Alias('Invoke-ePOwerShellQuery')]
    param (
        <#
            Specifies a predefined query that is stored on the ePO server. Can be provided by:

                * An ePOQuery object
                * A query ID
                * A query Name

            This parameter can be passed in from the pipeline.
        #>
        [Parameter(Mandatory = $True, Position = 0, ValueFromPipeline = $True, ParameterSetName = 'PremadeQuery')]
        $Query,

        <#
            .PARAMETER Table
                Specifies the table on the ePO server you would like to query against. Run Get-ePOTable to see available tables and values.
        #>
        [Parameter(Mandatory = $True, ParameterSetName = 'CustomQuery')]
        [System.String]
        $Table,

        <#
            .PARAMETER Select
                Specifies the items from tables you're specifically looking for. If a table name is not specified in your select string,
                then `$Table` is prepended to the beginning of your select item.
        #>
        [Parameter(Mandatory = $True, ParameterSetName = 'CustomQuery')]
        [System.String[]]
        $Select,

        <#
            .PARAMETER Where
                A hashtable used to limit the query to items meeting only specific criteria
        #>
        [Parameter(Mandatory = $True, ParameterSetName = 'CustomQuery')]
        [HashTable]
        $Where,

        <#
            .PARAMETER Database
                Optional parameter. Specifies a separate database to query, other than the default one.
        #>
        [Parameter(ParameterSetName = 'CustomQuery')]
        [Parameter(ParameterSetName = 'PremadeQuery')]
        [System.String]
        $Database
    )

    begin {
        try {
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
            foreach ($QueryItem in $Query) {
                switch ($PSCmdlet.ParameterSetName) {
                    'PremadeQuery' {
                        Write-Debug 'Using a premade query'
                        if ($QueryItem -is [ePOQuery]) {
                            Write-Debug 'ePOQuery object specified'
                            $Request.Query.queryId = $QueryItem.ID
                        } elseif ($QueryItem -is [Int32]) {
                            Write-Debug 'Query ID specified'
                            $Request.Query.queryId = $QueryItem
                        } else {
                            Write-Debug 'Query Name specified'

                            if (-not ($ePOQuery = Get-ePOQuery | Where-Object { $_.name -eq $QueryItem })) {
                                Write-Error ('Failed to find a query for: {0}' -f $QueryItem) -ErrorAction Stop
                            }

                            $Request.Query.queryId = $ePOQuery.ID
                        }

                        if ($Database) {
                            [Void] $Request.Query.Add('database', $Database)
                        }
                    }

                    'CustomQuery' {
                        $Select = foreach ($Item in $Select) {
                            if ($Item -Match '^(\S+\.){1,}\S+$') {
                                $Item
                            } else {
                                $Table + '.' + $Item
                            }
                        }

                        $Select = '(select ' + ($Select -Join ' ') + ')'
                        [Void] $Request.Query.Add('select', $Select)

                        if ($Where) {
                            $WhereString = Write-ePOWhere $Where
                            Write-Debug ('Where String: {0}' -f $WhereString)
                            [Void] $Request.Query.Add('where', $WhereString)
                        }
                    }
                }

                Write-Debug "Request: $($Request | ConvertTo-Json)"
                if (-not ($QueryResults = Invoke-ePORequest @Request)) {
                    Throw "Failed to find any ePO query results"
                }

                Write-Debug "Results: $($QueryResults | Out-String)"
                Write-Output $QueryResults
            }
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }

    end {}
}

Export-ModuleMember -Function 'Invoke-ePOQuery' -Alias 'Invoke-ePOwerShellQuery'