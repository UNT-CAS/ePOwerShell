<#
    .SYNOPSIS
        Returns saved $ePOwerShell settings

    .DESCRIPTION
        Returns an ePOConfig object of the saved information necessary to communicate with the ePO server

    .EXAMPLE
        Returns the currently set configuration for connecting to the ePO server.
        ```powershell
        $Config = Get-ePOConfig
        ```
#>

function Get-ePOConfig {
    [CmdletBinding()]
    [OutputType([Hashtable])]
    [Alias('Get-ePOwerShellServer', 'Get-ePOServer')]
    param ()

    process {
        try {
            if (-not ($Script:ePOwerShell)) {
                Write-Error 'ePO Server is not configured yet. Run Set-ePOConfig first' -ErrorAction Stop
            }

            Write-Output $Script:ePOwerShell
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}

Export-ModuleMember 'Get-ePOConfig' -Alias 'Get-ePOwerShellServer', 'Get-ePOServer'