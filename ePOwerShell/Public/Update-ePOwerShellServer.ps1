<#
.SYNOPSIS

    Required command. Sets the necessary parameters to successfully communicate with an ePO server

.DESCRIPTION

    This function sets up all information necessary to communicate with your ePO server.

    There are three ways to utilize this command: By manually specifying the variables each time you
    load the module, saving a json file on your computer with the necessary information, or saving the
    json as an environment variable, $env:ePOwerShell.

.PARAMETER Server

    URL to the ePO server

.PARAMETER Port

    Specifies the port necessary to communicate with the ePO server

.PARAMETER Credentials

    Credentials with access to the ePO server

.PARAMETER ePOwerShellSettings

    Specifies a path to a json containing all information necessary to connect to an ePO server

.EXAMPLE

    Update-ePOwerShellServer

.EXAMPLE

    Update-ePOwerShellServer -Server 'My-ePO-Server.domain.com'

#>

function Update-ePOwerShellServer {
    [CmdletBinding()]
    [Alias('Update-ePOServer')]
    param (
        [Parameter(Mandatory = $False)]
        [String]
        $Server = ($Script:ePOwerShell.Server),

        [Parameter(Mandatory = $False)]
        [Int]
        $Port = ($Script:ePOwerShell.Port),

        [Parameter(Mandatory = $False)]
        [System.Management.Automation.PSCredential]
        $Credentials = ($Script:ePOwerShell.Credentials)
    )

    if (-not ($script:ePOwerShell)) {
        Throw "Unable to set ePOwerShell server information. Either set '`$env:ePOwerShell', or run Set-ePOwerShellServer and specify all necessary information"
    }

    $ePOwerShellVariables = @{
        Server      = $Server
        Port        = $Port
        Credentials = $Credentials
    }

    Write-Debug "Variables: $($ePOwerShellVariables | Out-String)"

    Initialize-ePOwerShellVariables @ePOwerShellVariables
}