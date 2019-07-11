<#
    .SYNOPSIS
        Updates ePOwerShell config options individually, rather than setting everything at once.

    .DESCRIPTION
        This function sets up all information necessary to communicate with your ePO server.

        There are three ways to utilize this command: By manually specifying the variables each time you
        load the module, saving a json file on your computer with the necessary information, or saving the
        json as an environment variable, $env:ePOwerShell.

    .EXAMPLE
        Update-ePOwerShellServer -Server 'My-ePO-Server.domain.com'

        Update ePOwerShell to target a new server

    .PARAMETER Server
        URL to the ePO server

    .PARAMETER Port
        Specifies the port necessary to communicate with the ePO server

    .PARAMETER Credentials
        Credentials with access to the ePO server

    .PARAMETER AllowSelfSignedCerts
        Specifies if you'd like to allow ePOwerShell to allow self signed certificates on the ePO server

    .OUTPUTS
        None
#>

function Update-ePOConfig {
    [CmdletBinding(SupportsShouldProcess = $True, ConfirmImpact = "Low")]
    [Alias('Update-ePOwerShellServer', 'Update-ePOServer')]
    param (
        [System.String]
        $Server = ($Script:ePOwerShell.Server),

        [System.Int32]
        $Port = ($Script:ePOwerShell.Port),

        [System.Management.Automation.PSCredential]
        $Credentials = ($Script:ePOwerShell.Credentials),

        [Switch]
        $AllowSelfSignedCerts = ($Script:ePOwerShell.AllowSelfSignedCerts)
    )

    if (-not ($script:ePOwerShell)) {
        Throw "Unable to set ePOwerShell server information. Either set '`$env:ePOwerShell', or run Set-ePOwerShellServer and specify all necessary information"
    }

    $ePOwerShellVariables = @{
        Server               = $Server
        Port                 = $Port
        Credentials          = $Credentials
        AllowSelfSignedCerts = $AllowSelfSignedCerts
    }

    Write-Debug "Variables: $($ePOwerShellVariables | Out-String)"

    if ($PSCmdlet.ShouldProcess("Updating ePOwerShell configurations")) {
        Initialize-ePOConfig @ePOwerShellVariables
    }
}

Export-ModuleMember -Function 'Update-ePOConfig' -Alias 'Update-ePOwerShellServer', 'Update-ePOServer'