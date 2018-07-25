function Initialize-ePOwerShellVariables {
    [CmdletBinding()]
    [Alias('Initialize-ePOVariables')]
    param(
        [Parameter(Mandatory=$True)]
        [ValidateSet("json", "xml", "terse", "verbose")]
        [String]
        $Output,

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

    begin {}

    process {}

    end {
        $Script:ePOwerShell = @{
            Output = $Output
            Port = $Port
            Server = $Server
            Credentials = $Credentials
        }
    }
}