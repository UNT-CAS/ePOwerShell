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