<#
    .SYNOPSIS
        Returns the ePO version
#>

function Get-ePOVersion {
    [CmdletBinding()]
    [OutputType([System.String])]
    param ()

    begin {}
    process {
        try {
            $Request = @{
                Name = 'epo.getVersion'
            }

            Write-Debug "Request: $($Request | ConvertTo-Json)"
            if (-not ($Response = Invoke-ePORequest @Request)) {
                Throw 'Failed to determine ePO version'
            }

            Write-Output ($Response -as [System.Version])
        } catch {
            Write-Information $_ -Tags Exception
        }
    }

    end {}
}

Export-ModuleMember -Function 'Get-ePOVersion'