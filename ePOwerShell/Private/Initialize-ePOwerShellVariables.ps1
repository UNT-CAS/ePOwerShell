<#
.SYNOPSIS

    Called by Set-ePOwerShellServer, this function initializes the script scope variable, ePOwerShell
    which is used to communicate with the ePO server

.PARAMETER Server

    URL to the ePO server

.PARAMETER Port

    Specifies the port necessary to communicate with the ePO server

.PARAMETER Credentials

    Credentials with access to the ePO server
    
#>

function Initialize-ePOwerShellVariables {
    [CmdletBinding()]
    [Alias('Initialize-ePOVariables')]
    param(
        [Parameter(Mandatory=$True)]
        [Int]
        $Port,

        [Parameter(Mandatory=$True)]
        [String]
        $Server,

        [Parameter(Mandatory=$True)]
        [System.Management.Automation.PSCredential]
        $Credentials
    )

    $Script:ePOwerShell = @{
        Port        = $Port
        Server      = $Server
        Credentials = $Credentials
    }
}