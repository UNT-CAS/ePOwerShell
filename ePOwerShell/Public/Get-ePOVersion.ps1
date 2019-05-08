<#
    .SYNOPSIS
        Returns the ePO version
#>

function Get-ePOVersion {
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    process {
        try {
            $Request = @{
                Name = 'epo.getVersion'
            }

            Write-Debug "Request: $($Request | ConvertTo-Json)"
            $Response = Invoke-ePORequest @Request

            Write-Output $Response
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}