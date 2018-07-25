function Get-ePOwerShellServer {
    [CmdletBinding()]
    [Alias('Get-ePOServer')]
    param ()

    begin {}

    process {
        if ($env:ePOwerShell) {
            $ePOwerShellVariables = $env:ePOwerShell
        } else {
            $ePOwerShellVariables = @{
                Output      = $ePOwerShell.Output
                Port        = $ePOwerShell.Port
                Server      = $ePOwerShell.Server
                Credentials = $ePOwerShell.Credentials
            }
        }
    }

    end {
        return $ePOwerShellVariables
    }
}