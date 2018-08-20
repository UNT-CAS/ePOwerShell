<#
.SYNOPSIS

    Returns saved $ePOwerShell settings

.DESCRIPTION

    Returns a hashtable of the saved information necessary to communicate with the ePO server

.EXAMPLE

    Get-ePOwerShellTag

#>

function Get-ePOwerShellServer {
    [CmdletBinding()]
    [Alias('Get-ePOServer')]
    param ()

    if (-not ($Script:ePOwerShell)) {
        Throw [System.Management.Automation.ParameterBindingException] 'ePO Server is not configured yet. Run Set-ePOwerShellServer first!'
    }
    
    $ePOwerShellVariables = @{
        Port        = $Script:ePOwerShell.Port
        Server      = $Script:ePOwerShell.Server
        Credentials = $Script:ePOwerShell.Credentials
    }
    return $ePOwerShellVariables
}