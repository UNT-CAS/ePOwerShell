<#
.SYNOPSIS

    Required command. Sets the necessary parameters to successfully communicate with an ePO server

.DESCRIPTION

    This function sets up all information necessary to communicate with your ePO server.

    There are three ways to utilize this command: By manually specifying the variables each time you
    load the module, saving a json file on your computer with the necessary information, or saving the
    json as an environment variable, $env:ePOwerShell.

.EXAMPLE

    Update-ePOwerShellServer

.EXAMPLE

    Update-ePOwerShellServer -Server 'My-ePO-Server.domain.com'

#>

function Update-ePOConfig {
    [CmdletBinding(SupportsShouldProcess = $True)]
    [Alias('Update-ePOwerShellServer', 'Update-ePOServer')]
    param (
        <#
            .PARAMETER Server
                URL to the ePO server
        #>
        [System.String]
        $Server = ($Script:ePOwerShell.Server),

        <#
            .PARAMETER Port
                Specifies the port necessary to communicate with the ePO server
        #>
        [System.Int32]
        $Port = ($Script:ePOwerShell.Port),

        <#
            .PARAMETER Credentials
                Credentials with access to the ePO server
        #>
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

    if ($PSCmdlet.ShouldProcess("Updating ePOwerShell configurations")) {
        Initialize-ePOConfig @ePOwerShellVariables
    }
}