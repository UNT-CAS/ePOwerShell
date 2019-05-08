<#
    .SYNOPSIS
        Called by Set-ePOServer, this function initializes the script scope variable, ePOwerShell,
        which is used to communicate with the ePO server
#>

function Initialize-ePOConfig {
    [CmdletBinding()]
    param(
        <#
            .PARAMETER Server
                URL to the ePO server
        #>
        [Parameter(Mandatory=$True)]
        [System.String]
        $Server,

        <#
            .PARAMETER Credentials
                Credentials with access to the ePO server
        #>
        [Parameter(Mandatory=$True)]
        [System.Management.Automation.PSCredential]
        $Credentials,

        <#
            .PARAMETER Port
                Specifies the port necessary to communicate with the ePO server
        #>
        [System.Int32]
        $Port = 8443
    )

    $Script:ePOwerShell = @{
        Port        = $Port
        Server      = $Server
        Credentials = $Credentials
    }
}