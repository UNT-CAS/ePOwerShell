<#
.SYNOPSIS

    Returns saved $ePOwerShell settings

.DESCRIPTION

    Returns a hashtable of the saved information necessary to communicate with the ePO server

.EXAMPLE

    Get-ePOConfig
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

            $ePOwerShellVariables = @{
                Port        = $Script:ePOwerShell.Port
                Server      = $Script:ePOwerShell.Server
                Credentials = $Script:ePOwerShell.Credentials
            }

            Write-Output $ePOwerShellVariables
        } catch {
            Write-Information $_ -Tags Exception
            Throw $_
        }
    }
}