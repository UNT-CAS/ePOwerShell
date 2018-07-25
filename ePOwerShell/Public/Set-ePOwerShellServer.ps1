function Set-ePOwerShellServer {
    [CmdletBinding()]
    [Alias('Set-ePOServer')]
    param (
        [Parameter(Mandatory = $True)]
        [String]
        $Server,

        [Parameter(Mandatory = $True)]
        [Int]
        $Port,

        [Parameter(Mandatory = $True)]
        [ValidateSet("json", "xml", "terse", "verbose")]
        [String]
        $Output,

        [Parameter(Mandatory = $True)]
        [System.Management.Automation.PSCredential]
        $Credentials
    )

    begin {}

    process {
        if ($env:ePOwerShell) {
            $ePOwerShellVariables = $env:ePOwerShell
        } else {
            $ePOwerShellVariables = @{
                Output = $Output
                Port = $Port
                Server = $Server
                Credentials = $Credentials
            }
        }
    }

    end {
        Initialize-ePOwerShellVariables @ePOwerShellVariables
    }
}