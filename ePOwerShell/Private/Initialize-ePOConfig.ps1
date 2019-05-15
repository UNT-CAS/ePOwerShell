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

    if (-not ($Server.StartsWith('https://'))) {
        if ($Server.StartsWith('http://')) {
            Write-Verbose 'Server address starts with HTTP. Changing to HTTPS'
            $Server = $Server.Replace('http://', 'https://')
        } else {
            Write-Verbose 'Server address does not start with HTTPS. Changing...'
            $Server = 'https://' + $Server
        }

        Write-Verbose ('Updated server address: {0}' -f $Server)
    }

    $Script:ePOwerShell = @{
        Port        = $Port
        Server      = $Server
        Credentials = $Credentials
    }

    try {
        [Void] (Get-ePOHelp)
        Write-Verbose 'Successfully fetched ePOs core.help page'
    } catch {
        Remove-Variable ePOwerShell -Scope Script -Force
        Write-Information $_ -Tags Exception
        Throw $_
    }
}