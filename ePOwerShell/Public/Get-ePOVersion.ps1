<#
    .SYNOPSIS
        Returns the ePO version

    .DESCRIPTION
        Returns the version number of the McAfee ePO server

    .EXAMPLE
        Get-ePOVersion

        Returns the ePO version number

    .INPUTS
        None

    .OUTPUTS
        `[System.Version]`
#>

function Get-ePOVersion {
    [CmdletBinding()]
    [OutputType([System.Version])]
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