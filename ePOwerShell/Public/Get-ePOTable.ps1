<#
.SYNOPSIS
    Finds available tables in the ePO database

.DESCRIPTION
    Finds all available tables from the ePO database. Number of tables accessable may depend on your security permissions.

.EXAMPLE
    $Tables = Get-ePOTable

    Gets all available tables
#>

function Get-ePOTable {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
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
            if (-not ($ePOTables = Invoke-ePORequest @Request)) {
                Write-Error "Failed to find any ePO queries"
            }

            foreach ($ePOTable in $ePOTables) {
                Write-Output $ePOTable
            }
        } catch {
            Write-Information $_ -Tags Exception
        }
    }

    end {}
}

Export-ModuleMember -Function 'Get-ePOTable'